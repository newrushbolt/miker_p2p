$my_dir=File.expand_path(File.dirname(__FILE__))
$my_id=ARGV[0] ? ARGV[0] : 1
$my_name="#{File.basename(__FILE__,".rb")}_#{$my_id}"
$my_type=$my_name.sub(/\.worker.*/,"")

require 'etc'
require 'mysql2'
require 'bunny'
require 'rubygems'
require 'logger'
require 'json'
require 'geoip'
require 'ipaddr'

require "#{$my_dir}/etc/common.conf.rb"
if File.exists?("#{$my_dir}/etc/#{$my_name}.conf.rb")
	require "#{$my_dir}/etc/#{$my_name}.conf.rb"
end

if $default_user and RUBY_PLATFORM.include?('linux')
    begin
        proc_user=Etc.getpwnam($default_user)
        Process::Sys.setuid(proc_user.uid)
    rescue => e
        raise "Error while changing user to #{$default_user}, #{e.to_s}"
    end
end

$err_logger=Logger.new("#{$my_dir}/var/log/#{$my_name}.log")
$err_logger.info "Launched #{$my_name}"
$err_logger.level=$log_level
if ARGV[1]
    case ARGV[1]
    when "debug"
	$err_logger.level=Logger::DEBUG
    when "info"
	$err_logger.level=Logger::INFO
    when "warn"
	$err_logger.level=Logger::WARN
    when "error"
	$err_logger.level=Logger::ERROR
    when "fatal"
	$err_logger.level=Logger::FATAL
    end
end

begin
	require $whois_lib
	$slow_whois=Slow_whois.new
	require "#{$my_dir}/#{$validate_lib}"
	require "#{$my_dir}/#{$counters_lib}"
	$validator=Webrtc_validator.new
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while loading libs"
end

$geocity_client=GeoIP.new('var/geoip/GeoLiteCity.dat')

begin
	rabbit_client = Bunny.new(:hostname => "localhost")
	rabbit_client.start
	rabbit_channel = rabbit_client.create_channel()
	rabbit_slow_online = rabbit_channel.queue("slow_online_peers", :durable => true, :auto_delete => false)
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while connecting to RabbitMQ"
end

begin
	$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while connecting to MySQL"
end

def update_peers_info(peer)
	begin
		req="select * from #{$p2p_db_state_table} where conn_id = \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
		res=$p2p_db_client.query(req)
	rescue  => e
		$err_logger.error "Error in SQL request for #{peer["conn_id"]}"
		$err_logger.error e.to_s
		$err_logger.error req
		return false
	end
	$err_logger.debug "Base got any peer info? #{res.any?.to_s}"
	peer["timestamp"]=(peer["timestamp"].to_i / 1000).to_i
	if res.any?
		begin
			req="update #{$p2p_db_state_table} set last_update = \"#{peer["timestamp"]}\" where conn_id= \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
			res=$p2p_db_client.query(req)
			return true
		rescue  => e
			$err_logger.error "Error in DB update for #{peer["conn_id"]}"
			$err_logger.error e.to_s
			$err_logger.error req
			$err_logger.error peer
			return false
		end
	else
		aton_info=$slow_whois.get_ip_route(peer["ip"])
	end
	if ! aton_info or aton_info.nil? or !(aton_info["network"] and aton_info["netmask"] and aton_info["asn"])
		$err_logger.error "IP info for #{peer["ip"]} doesn't have enought info, only this:"
		$err_logger.error aton_info.to_s
		return false
	end
	peer["network"]=aton_info["network"]
	peer["netmask"]=aton_info["netmask"]
	peer["asn"]=aton_info["asn"]
	
	$err_logger.debug "Getting GeoIP info"
	begin
		geo_info=$geocity_client.city(peer["ip"])
	rescue  => e
		$err_logger.warn "Error in GeoIP for #{peer["ip"]}"
		$err_logger.warn e.to_s
	end
	
	if geo_info and geo_info.country_code3
		peer["country"]=geo_info.country_code3
	else
		$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have country_code3 info"
	end
	if geo_info and geo_info.real_region_name
		peer["region"]=geo_info.real_region_name
	else
		$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have real_region_name info"
	end
	if geo_info and geo_info.city_name
		peer["city"]=geo_info.city_name
	else
		$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have city_name info"
	end

	$err_logger.debug "Updating peer_info in SQL"
	begin
		req="insert into #{$p2p_db_state_table} values (\"#{peer["conn_id"]}\",\"#{peer["channel_id"]}\",\"#{peer["gg_id"]}\",#{peer["timestamp"]}, INET_ATON(\"#{peer["ip"]}\"),INET_ATON(\"#{peer["network"]}\"),INET_ATON(\"#{peer["netmask"]}\"),#{peer["asn"]},\"#{peer["country"]}\",\"#{peer["region"]}\",\"#{peer["city"]}\") ON DUPLICATE KEY UPDATE channel_id=\"#{peer["channel_id"]}\";"
		res=$p2p_db_client.query(req)
	rescue  => e
		$err_logger.error "Error in SQL insert for #{peer["conn_id"]}"
		$err_logger.error peer
		$err_logger.error e.to_s
		$err_logger.error req
		return false
	end
        aff=$p2p_db_client.affected_rows
        $err_logger.debug "#{aff} rows affected"
        if aff > 0
            return true
        else
            return false
        end
end

cnt_init($my_type)

while true
	rabbit_slow_online.subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
		peer=JSON.parse(body)
		#Temp fix fot ts
		peer["timestamp"]=Time.now.to_i() * 1000
		if $validator.v_conn_id(peer["conn_id"]) and $validator.v_channel_id(peer["channel_id"]) and $validator.v_gg_id(peer["gg_id"]) and $validator.v_ip(peer["ip"]) and $validator.v_ts(peer["timestamp"].to_i/1000)
			if update_peers_info(peer) == true
				$err_logger.info "Peer #{peer["conn_id"]} parsed successfull"
				cnt_up($my_type,"success")
			else
				req="insert into ip_bad_peers values (\"#{peer["conn_id"]}\",\"#{peer["channel_id"]}\",\"#{peer["gg_id"]}\",#{Time.now.to_i},INET_ATON(\"#{peer["ip"]}\")) ON DUPLICATE KEY UPDATE last_update=\"#{Time.now.to_i}\";"
				res=$p2p_db_client.query(req)
				$err_logger.warn "Parsing peer #{peer["conn_id"]} failed"
				cnt_up($my_type,"failed")
			end
		else
			$err_logger.error "Got incorrect peer:\n#{peer}"
			$err_logger.error "conn_id: #{$validator.v_conn_id(peer["conn_id"]).inspect}"
			$err_logger.error "channel_id: #{$validator.v_channel_id(peer["channel_id"]).inspect}"
			$err_logger.error "gg_id: #{$validator.v_gg_id(peer["gg_id"]).inspect}"
			$err_logger.error "ip: #{$validator.v_ip(peer["ip"]).inspect}"
			$err_logger.error "ts: #{$validator.v_ts(peer["timestamp"].to_i/1000).inspect}"
			cnt_up($my_type,"invalid")
		end
		rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
	end
end
