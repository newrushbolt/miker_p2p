require 'rubygems'
require 'sqlite3'
require 'rest-client'
require 'whois'
require 'json'
require 'geoip'
require 'mongo'

$peer_db_file='peers.sqlite3'
$peer_state_table='peer_state'
$peer_db=SQLite3::Database.new($peer_db_file)

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new('mongodb://127.0.0.1:27017/webrtc')
webrtc_raw_peers=mongo_client[:raw_peers]

def update_peers_info(peer)
#	peers.each do |peer|
		begin
			req="select * from #{$peer_state_table} where webrtc_id = \"#{peer["webrtc_id"]}\""
			res=$peer_db.execute(req)
		rescue  => e
			STDERR.puts "Error in DB update request"
			STDERR.puts e.to_s
			STDERR.puts req
			return false
		end
		if res.any?
			begin
				req="update #{$peer_state_table} set last_online = \"#{peer["timestamp"]}\" where webrtc_id= \"#{peer["webrtc_id"]}\";"
				res=$peer_db.execute(req)	
			rescue  => e
				STDERR.puts "Error in DB update for #{peer["ip"]}"
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
			peer["asn"]=aton_info[:asn].nil? ? 0 : aton_info[:asn]
			peer["netname"]=aton_info[:netname]
			peer["geo_country"]=geo_info.country_code3
			peer["geo_city"]=geo_info.city_name
			begin
				req="insert into #{$peer_state_table} values (\"#{peer["webrtc_id"]}\", \"#{peer["ip"]}\",#{peer["timestamp"]},\"#{peer["network"]}\",\"#{peer["netname"]}\",#{peer["asn"]},\"#{peer["geo_country"]}\",\"#{peer["geo_city"]}\");"
				res=$peer_db.execute(req)
				return true
			rescue  => e
				STDERR.puts "Error in DB insert for #{peer["ip"]}"
				STDERR.puts e.to_s
				STDERR.puts req
				STDERR.puts peer
				return false
			end
		end
#	end
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
