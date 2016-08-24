require 'rubygems'
require 'sqlite3'
require 'rest-client'
require 'whois'
require 'json'
require 'geoip'

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
#	puts whois_result
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

peer_db_file='peers.sqlite3'
peer_state_table='peer_state'
peer_db=SQLite3::Database.new(peer_db_file)

raw_log_txt='data\raw_log'
#raw_log_txt='c:\Users\Serge\Downloads\candy2.txt\candy2.txt'
raw_log_json=IO.read(raw_log_txt)

raw_log_data=JSON.parse(raw_log_json)["Logs"]
raw_log_json=""
raw_log_txt=""
cnt=0
raw_log_data.each do |peer|
	cnt+=1
	# puts peer["me"]["id"]
	# puts peer["ip"]
	# puts 'Requesting DB...'
	req="select * from #{peer_state_table} where webrtc_id = \"#{peer["me"]["id"]}\""
	# puts req
	res=peer_db.execute(req)
	# puts ! res.any? ? "Nothing found" : res
	if res.any?
		begin
			req="update #{peer_state_table} set last_online = \"#{peer["timestamp"]}\" where webrtc_id= \"#{peer["me"]["id"]}\";"
			res=peer_db.execute(req)	
	    rescue  => e
	        puts "Error in DB update for #{peer["ip"]}"
			puts e.to_s
			puts req
			puts peer
		end
	else
		aton_info=get_aton_info(peer["ip"])
		if aton_info.nil?
			 puts "Error in RIPE for #{peer["ip"]}"
		end
		begin
			geo_info=GeoIP.new('GeoLiteCity.dat').city(peer["ip"])
	    rescue  => e
	        puts "Error in GeoIP for #{peer["ip"]}"
			puts e.to_s
		end
#		puts aton_info
		peer["network"]=aton_info[:network]
		peer["asn"]=aton_info[:asn].nil? ? 0 : aton_info[:asn]
		peer["netname"]=aton_info[:netname]
		peer["geo_country"]=geo_info.country_code3
		peer["geo_city"]=geo_info.city_name
		# puts peer["asn"]
		# puts peer["network"]
		# puts peer["netname"]
		# puts peer["geo_country"]
		# puts peer["geo_city"]
		begin
			req="insert into #{peer_state_table} values (\"#{peer["me"]["id"]}\", \"#{peer["ip"]}\",#{peer["timestamp"]},\"#{peer["network"]}\",\"#{peer["netname"]}\",#{peer["asn"]},\"#{peer["geo_country"]}\",\"#{peer["geo_city"]}\");"
			res=peer_db.execute(req)
	    rescue  => e
	        puts "Error in DB insert for #{peer["ip"]}"
			puts e.to_s
			puts req
			puts peer
		end
	end
	if cnt.to_s.end_with?("00")
		puts "Done #{cnt.to_s} records"
	end
end

