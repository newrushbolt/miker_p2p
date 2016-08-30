require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'rest-client'
require 'whois'
require 'json'
require 'geoip'
require 'mongo'

$p2p_db=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)


Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
webrtc_raw_peers=mongo_client[:raw_peers]

def update_peers_info(peer)
		begin
			req="select * from #{$p2p_peer_state_table} where webrtc_id = \"#{peer["webrtc_id"]}\" and channel_id = \"#{peer["channel_id"]}\""
			res=$p2p_db.query(req)
		rescue  => e
			STDERR.puts "Error in DB request for #{peer["webrtc_id"]}"
			STDERR.puts e.to_s
			STDERR.puts req
			return false
		end
		puts res.to_s#
		if res.any?
			begin
				req="update #{$p2p_peer_state_table} set last_online = \"#{peer["timestamp"]}\" where webrtc_id= \"#{peer["webrtc_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
				res=$p2p_db.query(req)	
			rescue  => e
				STDERR.puts "Error in DB update for #{peer["webrtc_id"]}"
				STDERR.puts e.to_s
				STDERR.puts req
				STDERR.puts peer
				return false
			end
		else
			aton_info=get_aton_info(peer["ip"])
			if aton_info.nil?
				 STDERR.puts "Error in RIPE for #{peer["ip"]}"
			end
			begin
				geo_info=GeoIP.new('GeoLiteCity.dat').city(peer["ip"])
			rescue  => e
				STDERR.puts "Error in GeoIP for #{peer["ip"]}"
				STDERR.puts e.to_s
				return false
			end
			peer["network"]=aton_info[:network]
			peer["netmask"]=aton_info[:netmask]
			peer["asn"]=aton_info[:asn].nil? ? 0 : aton_info[:asn]
			peer["netname"]=aton_info[:netname]
			peer["country"]=geo_info.country_code3
			peer["region"]=geo_info.region
			peer["city"]=geo_info.city_name
			begin
				req="insert into #{$p2p_peer_state_table} values (\"#{peer["webrtc_id"]}\",\"#{peer["channel_id"]}\",\"#{peer["gg_id"]}\",#{peer["timestamp"]}, INET_ATON(#{peer["ip"]}),INET_ATON(#{peer["network"]}),INET_ATON(#{peer["netmask"]}),#{peer["asn"]},\"#{peer["country"]}\",\"#{peer["region"]}\",\"#{peer["city"]}\");"
				res=$p2p_db.query(req)
				return true
			rescue  => e
				STDERR.puts "Error in DB insert for #{peer["webrtc_id"]}"
				STDERR.puts e.to_s
				STDERR.puts req
				STDERR.puts peer
				return false
			end
		end
#	end
	raise 'fck'
end

def get_aton_info aton
    info_result = {}
    whois_client = Whois::Client.new
    begin
		aton_ip=IPAddr.new(aton)
        whois_result= whois_client.lookup(aton).to_s
    rescue  => e
        puts "Error while geting #{aton} info"
        puts e.to_s
        return nil
    end
    if whois_result and 
        whois_result.split("\n").each do |whois_result_line|
            if whois_result_line.start_with?("origin")
                info_result[:asn]=whois_result_line.gsub(/^origin\:[w| ]*(AS|as|As|aS)/, "")
            end
            if whois_result_line.start_with?("CIDR")
                info_result[:network]=whois_result_line.gsub(/^CIDR\:[w| ]*/, "")
            end
            if whois_result_line.start_with?("netname")
                info_result[:netname]=whois_result_line.gsub(/^netname\:[w| ]*/, "")
            end
            if whois_result_line.start_with?("NetName")
                info_result[:netname]=whois_result_line.gsub(/^NetName\:[w| ]*/, "")
            end
			if whois_result_line.start_with?("route")
                info_result[:network]=whois_result_line.gsub(/^route\:[w| ]*/, "")
            end
        end
    end
    return info_result
end

webrtc_raw_peers_cursor = webrtc_raw_peers.find({unchecked: 1}, cursor_type: :tailable_await).to_enum

while true
	if webrtc_raw_peers_cursor.any?
		raw_peer = webrtc_raw_peers_cursor.next
		puts raw_peer["webrtc_id"]
		if update_peers_info(raw_peer)
			begin
				webrtc_raw_peers.update_one({webrtc_id: raw_peer["webrtc_id"]},{"$set":{unchecked: 0}})
			rescue => e
				STDERR.puts "Error while setting checked flag to #{raw_peer["webrtc_id"]}"
				STDERR.puts e.to_s
			end
		end
	end
	sleep(0.1)
end
