require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'benchmark'
require 'whois'
require 'ipaddr'
require 'mysql2'
require 'sinatra'

$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
#$p2p_db_inetnums_tabl
networks=[]
	begin
		req="select inet_ntoa(network),inet_ntoa(netmask),asn from #{$p2p_db_inetnums_table} limit 10;"
		res=$p2p_db_client.query(req)
	rescue => e
		puts e.to_s
		puts req
	end
	inetnums=res
	inetnums.each do |inetnum|
		begin
			network=IPAddr.new(inetnum["inet_ntoa(network)"],Socket::AF_INET)
			network.mask(inetnum["inet_ntoa(netmask)"])
		rescue => e
			puts e.to_s
			puts inetnum
		end
		networks.push(network)
	end
puts network.to_s
