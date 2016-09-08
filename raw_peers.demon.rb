require "#{Dir.pwd}/config.rb"
require 'logger'
require 'rubygems'
require 'mysql2'
require 'rest-client'
require 'whois'
require 'json'
require 'geoip'
require 'mongo'
require 'etc'

if $default_user
    begin
        proc_user=Etc.getpwnam($default_user)
        Process::Sys.setuid(proc_user.uid)
    rescue => e
        puts "Error while changing user to #{$default_user}"
        puts e.to_s
    end
end

$out_logger=Logger.new("#{$log_dir}/raw_peer.demon.out.log")
$err_logger=Logger.new("#{$log_dir}/raw_peer.demon.err.log")

if ARGV[0]
    case ARGV[0]
    when debug
	$out_logger.level=Loger::DEBUG
	$err_logger.level=Loger::DEBUG
    when info
	$out_logger.level=Loger::INFO
	$err_logger.level=Loger::IFNO
    when warn
	$out_logger.level=Loger::WARN
	$err_logger.level=Loger::WARN
    when error
	$out_logger.level=Loger::ERROR
	$err_logger.level=Loger::ERROR
    when fatal
	$out_logger.level=Loger::FATAL
	$err_logger.level=Loger::FATAL
    end
    $out_logger.level=Loger::ERROR
    $err_logger.level=Loger::ERROR
end

$p2p_db_client = nil
$mongo_client = nil
$webrtc_raw_peers= nil
$webrtc_raw_peers_cursor= nil

def update_peers_info(peer)
		begin
			req="select * from #{$p2p_db_state_table} where webrtc_id = \"#{peer["webrtc_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
			res=$p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in DB request for #{peer["webrtc_id"]}"
			$err_logger.error e.to_s
			$err_logger.error req
			return false
		end
		$out_logger.debug "Base got any peer info? #{res.any?.to_s}"
		if res.any?
		    return true
		###disabled till log parse is off
			# begin
				# req="update #{$p2p_db_state_table} set last_update = \"#{peer["timestamp"]}\" where webrtc_id= \"#{peer["webrtc_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
				# res=$p2p_db_client.query(req)	
				# return true
			# rescue  => e
				# $err_logger.error "Error in DB update for #{peer["webrtc_id"]}"
				# $err_logger.error e.to_s
				# $err_logger.error req
				# $err_logger.error peer
				# return false
			# end
		else
			aton_info=get_aton_info(peer["ip"])
			if ! (aton_info["network"] and aton_info["netmask"] and aton_info["asn"])
				 $err_logger.error "IP info for #{peer["ip"]} doesn't have enought info"
				 $err_logger.error aton_info.to_s
				 return false
			end
			begin
				geo_info=GeoIP.new('GeoLiteCity.dat').city(peer["ip"])
			rescue  => e
				$err_logger.error "Error in GeoIP for #{peer["ip"]}"
				$err_logger.error e.to_s
				return false
			end
			if ! (geo_info.country_code3 and geo_info.real_region_name and geo_info.city_name)
				 $err_logger.error "GeoIP info for #{peer["ip"]} doesn't have enought info"
				 $err_logger.error aton_info.to_s
			end
			peer["network"]=aton_info["network"]
			peer["netmask"]=aton_info["netmask"]
			peer["asn"]=aton_info["asn"]
			peer["country"]=geo_info.country_code3
			peer["region"]=geo_info.real_region_name
			peer["city"]=geo_info.city_name
			peer["timestamp"]=(peer["timestamp"].to_i / 1000).to_i
			begin
				req="insert into #{$p2p_db_state_table} values (\"#{peer["webrtc_id"]}\",\"#{peer["channel_id"]}\",\"#{peer["gg_id"]}\",#{peer["timestamp"]}, INET_ATON(\"#{peer["ip"]}\"),INET_ATON(\"#{peer["network"]}\"),INET_ATON(\"#{peer["netmask"]}\"),#{peer["asn"]},\"#{peer["country"]}\",\"#{peer["region"]}\",\"#{peer["city"]}\");"
				res=$p2p_db_client.query(req)
				return true
			rescue  => e
				$err_logger.error "Error in DB insert for #{peer["webrtc_id"]}"
				$err_logger.error e.to_s
				$err_logger.error req
				$err_logger.error peer
				return false
			end
		end
end

def get_aton_info(aton)
    info_result = {}
    whois_client = Whois::Client.new
    begin
		aton_ip=IPAddr.new(aton)
        whois_result= whois_client.lookup(aton).to_s
    rescue  => e
        $err_logger.error "Error while geting #{aton} info"
        $err_logger.error e.to_s
        return nil
    end
    if whois_result and 
        whois_result.split("\n").each do |whois_result_line|
            if whois_result_line.start_with?("origin")
                info_result["asn"]=whois_result_line.gsub(/^origin\:[w| ]*(AS|as|As|aS)/, "")
            end
            if whois_result_line.start_with?("CIDR")
                info_result["network"]=whois_result_line.gsub(/^CIDR\:[w| ]*/, "")
            end
			if whois_result_line.start_with?("route")
				ip_obj=IPAddr.new(whois_result_line.gsub(/^route\:[w| ]*/, ""))
				info_result["network"]=ip_obj.to_s
				info_result["netmask"]=ip_obj.inspect.gsub(/^\#.*\//,"").delete(">")
            end
        end
    end
    return info_result
end

def start_worker
	$err_logger.info "Started worker"
	begin
		Mongo::Logger.logger.level = Logger::WARN
		$mongo_client = Mongo::Client.new($mongo_url, :min_pool_size => 10 , :max_pool_size => 50)
		$webrtc_raw_peers=$mongo_client[:raw_peers]
		$webrtc_raw_peers_cursor = $webrtc_raw_peers.find({unchecked: 1}, cursor_type: :tailable_await).to_enum
	rescue => e
		$err_logger.error "Error while connecting to MongoDB"
		$err_logger.error e.to_s
		return false
	end

	begin
		$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
	rescue => e
		$err_logger.error "Error while connecting to MongoDB"
		$err_logger.error e.to_s
		return false
	end
	
	while true
		begin
			if $webrtc_raw_peers_cursor.any?
				raw_peer = $webrtc_raw_peers_cursor.next
				$out_logger.info "webrtc_id #{raw_peer["webrtc_id"]}; channel_id #{raw_peer["channel_id"]}"
				up_info=update_peers_info(raw_peer)
				$out_logger.debug "SQL peer update returned #{up_info.to_s}"
				if up_info
					begin
						$out_logger.debug "$webrtc_raw_peers.update_one({webrtc_id: #{raw_peer["webrtc_id"]}},{\"$set\":{unchecked: 0}})"
						$webrtc_raw_peers.update_one({webrtc_id: raw_peer["webrtc_id"]},{"$set":{unchecked: 0}})
					rescue => e
						$err_logger.error "Error while setting checked flag to #{raw_peer["webrtc_id"]}"
						$err_logger.error e.to_s
					end
				end
			end
		rescue => e
			$err_logger.error "Error while getting cursor updates from MongoDB"
			$err_logger.error e.to_s
			return false
		end
		sleep(0.01)
	end
end

while true
	res=start_worker
	$err_logger.error "Worker is dead"
	sleep(1)
end
