require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'benchmark'
require 'whois'
require 'logger'
require 'ipaddr'
require 'mysql2'
require 'sinatra'

$out_logger=Logger.new("log/whois.log")
$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
$networks=[]

begin
	req="select inet_ntoa(network),inet_ntoa(netmask),asn from #{$p2p_db_inetnums_table};"
	res=$p2p_db_client.query(req)
rescue => e
	puts e.to_s
	puts req
end
inetnums=res

inetnums.each do |inetnum|
	line={}
	begin
		line["ip_obj"]=IPAddr.new(inetnum["inet_ntoa(network)"],Socket::AF_INET).mask(inetnum["inet_ntoa(netmask)"])
		line["network"]=inetnum["inet_ntoa(network)"]
		line["netmask"]=inetnum["inet_ntoa(netmask)"]
		line["asn"]=inetnum["asn"]
	rescue => e
		puts e.to_s
		puts inetnum
	end
	$networks.push(line)
	$out_logger.info(line["ip_obj"].inspect)
end

def get_ip_info(ip)
	$result=[]
	if $networks.any?
		$networks.each do |network|
			if network["asn"] and network["network"] and network["netmask"] and network["ip_obj"]
				network_out=network
				$out_logger.info("compare #{network["ip_obj"].inspect} to #{ip}")
				if network["ip_obj"].include?(ip)
					network_out.delete("ip_obj")
					$result.push(network_out)
				end
			end
		end
	else
		$return={"error" => "no network loaded"}
	end
	if ! $result.any?
		$result={"error" => "not found any match for #{ip}"}
	end
	$out_logger.info(JSON.generate($result))
	return JSON.generate($result)
end

configure do
	set :port, '3301'
	set :bind, '127.0.0.1'
end

get '/ip' do
	if params['ip'].nil?
		'Error,nil ip'
	else
		response=get_ip_info(params['ip'])
	end
end
