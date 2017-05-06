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

def db_got_peer(peer)
	begin
		req="select * from #{$p2p_db_state_table} where conn_id = \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
	rescue  => e
		$err_logger.error "Error in SQL request for #{peer["conn_id"]}"
		$err_logger.error e.to_s
		$err_logger.error req
		return false
	end
	$err_logger.debug "Base got any peer info? #{res.any?.to_s}"
	if res.any?
		return true
	end
	return false
end

begin
	require "#{$my_dir}/#{$validate_lib}"
	require "#{$my_dir}/#{$counters_lib}"
	$validator=Webrtc_validator.new	
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while loading libs"
end

begin
	rabbit_client = Bunny.new(:hostname => "localhost")
	rabbit_client.start
	rabbit_channel = rabbit_client.create_channel()
	rabbit_peer_log = rabbit_channel.queue("peer_log", :durable => true, :auto_delete => false)
	rabbit_common_online  = rabbit_channel.queue("common_online_peers", :durable => true, :auto_delete => false)
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

cnt_init($my_type)

while true
	rabbit_peer_log.subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
		peer=JSON.parse(body)
		$err_logger.debug "Got log:\n#{peer}"
		if $validator.v_peer_log_entry(peer)
			$err_logger.debug "Finding seed in peer_state db"
			if db_got_peer(peer)
				begin
					req="update #{$p2p_db_state_table} set last_update = \"#{peer["timestamp"]}\" where conn_id= \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
					res=$p2p_db_client.query(req)	
				rescue  => e
					$err_logger.error "Error in DB update for #{peer["conn_id"]}"
					$err_logger.error e.to_s
					$err_logger.error req
					$err_logger.error peer
				end
		    else
				$err_logger.info "Peer #{peer["conn_id"]} doesnt exist in peer_state db, adding to common queue"
				online_peer={}
				online_peer["conn_id"]=peer["conn_id"]
				online_peer["gg_id"]=peer["gg_id"]
				online_peer["channel_id"]=peer["channel_id"]
				online_peer["ip"]=peer["ip"]
				online_peer["timestamp"]=peer["timestamp"]
				rabbit_common_online.publish(JSON.generate(online_peer), :routing_key => rabbit_common_online.name, :persistent => false)
		    end
			$err_logger.debug "Updating good_peer in SQL"
			good_peer=peer["good_peer"]
			puts good_peer["Conn_id"]
			if good_peer["P2p"].to_i > 0 and $validator.v_conn_id(good_peer["Conn_id"])
				begin
					req="insert ignore into #{$p2p_db_peer_load_table} values (\"#{good_peer["Conn_id"]}\",#{peer["timestamp"].to_i},\"#{peer["conn_id"]}\",#{good_peer["P2p"]},#{good_peer["Ltime"]});"
					$err_logger.debug req
					res=$p2p_db_client.query(req)
				rescue => e
					$err_logger.error "Error in SQL insert for good_peer: #{good_peer}"
					$err_logger.error peer
					$err_logger.error req
					$err_logger.error e.to_s
				end
				aff=$p2p_db_client.affected_rows
				$err_logger.debug "#{aff} rows affected"
			end
			$err_logger.debug "Updating bad_peers in SQL"
			bad_peer=peer["bad_peer"]
			if $validator.v_conn_id(bad_peer["Conn_id"])
				begin
					req="insert ignore into #{$p2p_db_bad_peer_table} values (\"#{bad_peer["Conn_id"]}\",#{peer["timestamp"].to_i},\"#{peer["conn_id"]}\");"
					$err_logger.debug req
					res=$p2p_db_client.query(req)
				rescue => e
					$err_logger.error "Error in SQL insert for bad_peer: #{bad_peer}"
					$err_logger.error peer
					$err_logger.error req
					$err_logger.error e.to_s
				end
				aff=$p2p_db_client.affected_rows
				$err_logger.debug "#{aff} rows affected"
			end
			cnt_up($my_type,"success")
		else
			$err_logger.error "Got incorrect peer:\n#{peer}"
			$err_logger.error "Fields validation:#{$validator.v_log_fields(peer,fields).inspect}"
			$err_logger.error "conn_id: #{$validator.v_conn_id(peer["conn_id"]).inspect}"
			$err_logger.error "ip: #{$validator.v_ip(peer["ip"]).inspect}"
			$err_logger.error "ts: #{$validator.v_ts(peer["timestamp"].to_i).inspect}"
			cnt_up($my_type,"invalid")
		end
		rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
	end
end
