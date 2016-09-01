require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'ipaddr'
require 'mysql2'

$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)

def get_apnic_latest_db

end

def parse_apnic_latest_db

end

def get_ripe_latest_db

end

def parse_ripe_latest_db
	inetnums=[]
	begin
		data_raw=File.read("#{$ripe_db_dir}/latest_routes")
#File format, maybe pre-parse them harder
# route:          193.254.30.0/24
# origin:         AS12726
# route:          212.166.64.0/19
# origin:         AS12321
# route:          212.80.191.0/24
# origin:         AS12541
	rescue => e
		puts e.to_s
	end
	data=data_raw.gsub("\norigin:",",origin:").gsub("origin:","").gsub("route:","").delete(" ")
	data.split("\n").each do |unit|
		line={}
		ip=IPAddr.new(unit.split(",")[0])
		begin
			line["asn"]=unit.split(",")[1].gsub(/\D/,"")
		rescue => e
			puts e.to_s
			puts unit
			exit
		end
		line["netmask"]=ip.inspect.gsub(/^\#.*\//,"").delete(">")
		line["network"]=ip.to_s
		inetnums.push(line)
	end
	return inetnums
end

inetnums=parse_ripe_latest_db
inetnums.each do |inetnum|
	begin
		req="insert ignore into #{$p2p_db_inetnums_table} values (inet_aton(\"#{inetnum["network"]}\"),inet_aton(\"#{inetnum["netmask"]}\"),#{inetnum["asn"]});"
		res=$p2p_db_client.query(req)
	rescue => e
		puts e.to_s
		puts req
	end
end