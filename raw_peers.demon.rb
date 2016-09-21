require 'etc'
require 'geoip'
require 'json'
require 'logger'
require 'mongo'
require 'mysql2'
require 'rest-client'
require 'rubygems'
require 'ruby-prof'
require 'whois'

require "#{Dir.pwd}/config.rb"
if $use_fast_whois_lib 
	require $fast_whois_lib
end

if $default_user and RUBY_PLATFORM.include?('linux')
    begin
        proc_user=Etc.getpwnam($default_user)
        Process::Sys.setuid(proc_user.uid)
    rescue => e
        puts "Error while changing user to #{$default_user}"
        puts e.to_s
    end
end

$err_logger=Logger.new("#{$log_dir}/raw_peer.demon.err.log")
$err_logger.level=$log_level

if ARGV[0]
    case ARGV[0]
    when 'debug'
	$err_logger.level=Logger::DEBUG
    when 'info'
	$err_logger.level=Logger::IFNO
    when 'warn'
	$err_logger.level=Logger::WARN
    when 'error'
	$err_logger.level=Logger::ERROR
    when 'fatal'
	$err_logger.level=Logger::FATAL
    end
end

$p2p_db_client = nil
$mongo_client = nil
$webrtc_raw_peers= nil
$webrtc_raw_peers_cursor= nil

$private_ip_nets=[]
$private_nets.each do |net|
	$private_ip_nets.push(IPAddr.new(net))
	$err_logger.debug "Loading private IP-net #{net}"
end

def update_peers_info(peer)
	begin
		req="select * from #{$p2p_db_state_table} where webrtc_id = \"#{peer["webrtc_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
		res=$p2p_db_client.query(req)
	rescue  => e
		$err_logger.error "Error in SQL request for #{peer["webrtc_id"]}"
		$err_logger.error e.to_s
		$err_logger.error req
		return false
	end
	$err_logger.debug "Base got any peer info? #{res.any?.to_s}"
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
		if $use_fast_whois_lib 
			$err_logger.debug "Using old whois call"
			aton_info=get_info(peer["ip"])
		else
			$err_logger.debug "Using fast_whois_lib"
			aton_info=get_aton_info(peer["ip"])
		end
		if ! aton_info or aton_info.nil? or !(aton_info["network"] and aton_info["netmask"] and aton_info["asn"])
			 $err_logger.error "IP info for #{peer["ip"]} doesn't have enought info, only this:"
			 $err_logger.error aton_info.to_s
			 return false
		end
		peer["network"]=aton_info["network"]
		peer["netmask"]=aton_info["netmask"]
		peer["asn"]=aton_info["asn"]
		peer["timestamp"]=(peer["timestamp"].to_i / 1000).to_i
		
		$err_logger.debug "Getting GeoIP info"			
		begin
			geo_info=GeoIP.new('GeoLiteCity.dat').city(peer["ip"])
		rescue  => e
			$err_logger.warn "Error in GeoIP for #{peer["ip"]}"
			$err_logger.warn e.to_s
		end
		
		if geo_info.country_code3
			peer["country"]=geo_info.country_code3
		else
			$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have country_code3 info"
		end
		if geo_info.real_region_name
			peer["region"]=geo_info.real_region_name
		else
			$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have real_region_name info"
		end
		if geo_info.city_name
			peer["city"]=geo_info.city_name
		else
			$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have city_name info"
		end

		$err_logger.debug "Updating peer_info in SQL"		
		begin
			req="insert into #{$p2p_db_state_table} values (\"#{peer["webrtc_id"]}\",\"#{peer["channel_id"]}\",\"#{peer["gg_id"]}\",#{peer["timestamp"]}, INET_ATON(\"#{peer["ip"]}\"),INET_ATON(\"#{peer["network"]}\"),INET_ATON(\"#{peer["netmask"]}\"),#{peer["asn"]},\"#{peer["country"]}\",\"#{peer["region"]}\",\"#{peer["city"]}\");"
			res=$p2p_db_client.query(req)
			return true
		rescue  => e
			$err_logger.error "Error in SQL insert for #{peer["webrtc_id"]}"
			$err_logger.error peer
			$err_logger.error e.to_s
			$err_logger.error req
			return false
		end
	end
end

#Old block, ll be removed soon
def get_aton_info(aton)
	$err_logger.debug "Started <get_aton_info> for #{aton}"
    info_result = {}
    whois_client = Whois::Client.new
    begin
		IPAddr.new(aton)
		$private_ip_nets.each do |net|
			if net.include?(aton)
				$err_logger.error "IP #{aton} is in private net #{net.inspect}, exiting"
				return nil
			end
		end
        whois_result= whois_client.lookup(aton).to_s
    rescue  => e
        $err_logger.error "Error while geting whois info for #{aton}"
        $err_logger.error e.to_s
        return nil
    end
	# $err_logger.debug "Got whois response for #{aton} :"
	# $err_logger.debug whois_result
    if whois_result and 
        whois_result.split("\n").each do |whois_result_line|
			begin
				if whois_result_line.start_with?("origin")
					$err_logger.debug "Found Origin(ASN) line:"
					$err_logger.debug whois_result_line
					info_result["asn"]=whois_result_line.gsub(/^origin\:[w| ]*(AS|as|As|aS)/, "").to_i
				end
				if whois_result_line.start_with?("CIDR")
					$err_logger.debug "Found CIDR(route) line:"
					$err_logger.debug whois_result_line
					ip_obj=IPAddr.new(whois_result_line.gsub(/^CIDR\:[w| ]*/, ""))
					info_result["network"]=ip_obj.to_s
					info_result["netmask"]=ip_obj.inspect.gsub(/^\#.*\//,"").delete(">")
				end
				if whois_result_line.start_with?("route")
					$err_logger.debug "Found route line:"
					$err_logger.debug whois_result_line
					ip_obj=IPAddr.new(whois_result_line.gsub(/^route\:[w| ]*/, ""))
					info_result["network"]=ip_obj.to_s
					info_result["netmask"]=ip_obj.inspect.gsub(/^\#.*\//,"").delete(">")
				end
			rescue => e
				$err_logger.error "Cannot parse whois line for #{aton}"
				$err_logger.error whois_result_line
			end
        end
    end
	if info_result["network"] and info_result["netmask"] and ! info_result["asn"]
		$err_logger.warn "Got no ASN for #{aton}, trying geoip base"
		begin
			geo_info=GeoIP.new('GeoIPASNum.dat').asn(aton)
			asn=geo_info[:number].gsub(/^*(AS|as|As|aS)/, "").to_i
			info_result["asn"]=asn
		rescue  => e
			$err_logger.error "Error in GeoIPASNum request for #{aton}"
			$err_logger.error e.to_s
			return false
		end
		$err_logger.debug "Got asn: #{asn}"
		$err_logger.debug asn
	end
	$err_logger.debug "Finished with no errors"
	$err_logger.debug info_result.to_s
    return info_result
end

def start_worker
	$err_logger.info "Started worker"
	begin
		Mongo::Logger.logger.level = Logger::WARN
		$mongo_client = Mongo::Client.new($mongo_url, :min_pool_size => 1 , :max_pool_size => 1)
		$webrtc_raw_peers=$mongo_client[:raw_peers]
		$webrtc_raw_peers_cursor = $webrtc_raw_peers.find({unchecked: 1}, cursor_type: :tailable_await).to_enum
	rescue => e
		$err_logger.error "Error while connecting to MongoDB"
		$err_logger.error e.to_s
		return false
	end

	begin
		$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
	rescue => e_main
		$err_logger.error "Error while connecting to MySQL"
		$err_logger.error e_main.to_s
		return false
	end
	
	start_ts=Time.now.to_i
	while true
		begin
			if $webrtc_raw_peers_cursor.any?
				raw_peer = $webrtc_raw_peers_cursor.next
				$err_logger.info "Adding peer, webrtc_id => #{raw_peer["webrtc_id"]}; channel_id => #{raw_peer["channel_id"]}"
				up_info=update_peers_info(raw_peer)
				$err_logger.debug "SQL peer update returned #{up_info.to_s}"
				if up_info
					begin
						$err_logger.debug "$webrtc_raw_peers.update_one({webrtc_id: #{raw_peer["webrtc_id"]}},{\"$set\":{unchecked: 0}})"
						$webrtc_raw_peers.update_one({webrtc_id: raw_peer["webrtc_id"]},{"$set":{unchecked: 0}})
					rescue => e
						$err_logger.error "Error while setting Unchecked => 0 to #{raw_peer["webrtc_id"]}"
						$err_logger.error e.to_s
					end
				else
					$err_logger.error "SQL update failed for peer #{raw_peer["webrtc_id"]}, leaving it unchecked"
				end
			end
		rescue => e_main
			$err_logger.error "Error while getting cursor updates from MongoDB"
			$err_logger.error e_main.to_s
			return false
		end
		cur_ts=Time.now.to_i
		if cur_ts > (start_ts + 300)
		    $err_logger.info "Time to die"
		    $mongo_client.close
		    return false
		end
		sleep(0.05)
	end
end

while true
	res=start_worker
	$err_logger.error "Worker is dead"
	sleep(1)
end
