require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'ipaddr'
require 'mysql2'

$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
$inetnums=[]

def get_db(url,rr_name)
	if url.ends_with?('.gz')
		req="curl #{url} -o #{Dir.pwd}/data/#{rr_name}.db.gz;gzip -d #{Dir.pwd}/data/#{rr_name}.db.gz;grep -e '^route:|^origin:'>#{Dir.pwd}/data/#{rr_name}.routes"
	else
		req="curl #{url} -o #{Dir.pwd}/data/#{rr_name}.db;grep -e '^route:|^origin:'>#{Dir.pwd}/data/#{rr_name}.routes"
	end
	res=system(req)
	return res
end

def parse_db(filename)
	begin
		data_raw=File.read(filename)
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

$rr_urls.each do |rr_url|
	rr_name=rr_url.gsub("ftp://ftp.","").gsub(/\.net.*/,"")
	puts rr_name
	if get_db(rr_url,rr_name)==true
		$inetnums=$inetnums | parse_db("#{Dir.pwd}/data/#{rr_name}.db")
	else
		puts 'failed to get db'
	end
end

$inetnums.each do |inetnum|
	begin
		req="insert ignore into #{$p2p_db_inetnums_table} values (inet_aton(\"#{inetnum["network"]}\"),inet_aton(\"#{inetnum["netmask"]}\"),#{inetnum["asn"]});"
		res=$p2p_db_client.query(req)
	rescue => e
		puts e.to_s
		puts req
	end
end

req="insert replace into #{$p2p_db_inetnums_table} select * from #{$p2p_db_fast_inetnums_table};"
res=$p2p_db_client.query(req)


