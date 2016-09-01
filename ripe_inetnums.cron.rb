require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'whois'
require 'ipaddr'
require 'mysql2'

$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
#$p2p_db_inetnums_tabl
def prefix2netmask(prefix)
	
end

def get_ripe_latest_db

end

def parse_ripe_latest_db
	inetnums=[]
	begin
		data_raw=File.read('data\routes')
	rescue => e
		puts e.to_s
	end
	data=data_raw.gsub("\norigin:",",origin:").gsub("origin:","").gsub("route:","").delete(" ")
	data.split("\n").each do |unit|
		line={}
		ip=IPAddr.new(unit.split(",")[0])
		line["asn"]=unit.split(",")[1].gsub("AS","")
		line["netmask"]=ip.inspect.gsub(/^\#.*\//,"").delete(">")
		line["network"]=ip.to_s
		inetnums.push(line)
	end
	return inetnums
end

inetnums=parse_ripe_latest_db
inetnums.each do |inetnum|
	req="insert ignore into #{$p2p_db_inetnums_table} values (inet_aton(\"#{inetnum["network"]}\"),inet_aton(\"#{inetnum["network"]}\"),#{inetnum["asn"]});"
	res=$p2p_db_client.query(req)
end