require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'ipaddr'
require 'mysql2'

$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
$inetnums=[]

def get_db(url,rr_name,db_filename)
	if ! File.exists?(db_filename)
	if url.end_with?('.gz')
		req="curl #{url} -o #{db_filename}.gz;gzip -df #{db_filename}.gz"
	else
		req="curl #{url} -o #{db_filename}"
	end
	return res
	else
	res=true
	return res
	end

end

def parse_db(db_filename)
	inetnums=[]
	begin
		data_raw=File.read(db_filename).encode('utf-8', :invalid => :replace, :undef => :replace)
	rescue => e
		puts e.to_s
	end
	data_raw.split("\n\n").each do |raw_object|
	    if raw_object.start_with?("route:")
		begin

		raw_ip=raw_object.match(/^route:.*$/).to_s.gsub(/^route:[\ ]*/,"").delete(" ")
		raw_asn=raw_object.match(/^origin:.*$/).to_s.gsub(/^origin:[\ ]*(AS|as|As|aS)/,"").delete(" ").to_i
		rescue => e
			puts 'error while converting object data'
			puts raw_object
			puts e.to_s
			raw_ip=nil
			raw_asn=nil
		end

		line={}
		begin
			ip=IPAddr.new(raw_ip)
		rescue => e
			puts e.to_s
		end
		line["asn"]=unit.split(",")[1].gsub(/\D/,"")
		line["netmask"]=ip.inspect.gsub(/^\#.*\//,"").delete(">")
		line["network"]=ip.to_s
		inetnums.push(line)
	end
	return inetnums
end

$rr_urls.each do |rr_url|
	rr_name=rr_url.gsub("ftp://ftp.","").gsub(/\.net.*/,"")
	puts rr_name
	db_filename="#{Dir.pwd}/data/#{rr_name}.db"
	routes_filename="#{Dir.pwd}/data/#{rr_name}.routes"
	if get_db(rr_url,rr_name,db_filename)==true
		$inetnums=$inetnums | parse_db(db_filename)
	else
		puts 'failed to get db'
	end
exit
end

puts inetnums.lenght
exit

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


