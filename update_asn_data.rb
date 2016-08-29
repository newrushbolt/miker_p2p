require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'sqlite3'
require 'rest-client'
require 'whois'
require 'json'
require 'mongo'

$peer_db=SQLite3::Database.new($peer_db_file)

def get_asn_prefixes(asn)
	asn_peers=[]
	req="#{$ripe_as_con_url}resource=AS#{asn}"
	puts req
	res=RestClient.get(req).body
	asn_raw_peers=JSON.parse(res)["data"]["exports"]
	
	insert
	asn_raw_peers.each do |raw_peer|
		asn_peers.push(raw_peer["peer"])
		
	end
	
	
	
	puts asn_peers
	raise 'exit'
	ts_e=Time.now().to_i
	puts ts_e
	ts_s=ts_e - 2592000
	puts ts_s
	req="#{$ripe_prefix_url}resource=AS#{asn}&starttime=#{ts_s}"
	#&endtime=#{ts_e}"
	puts req
	res=RestClient.get(req).body
	puts res
end


req="select asn from #{$ix_list_table};"
res=$peer_db.execute(req)
ix_list=res
puts ix_list.to_s

if ix_list.any?
	ix_list.each do |ix|
		req="select count(asn) from #{$asn_prefix_table} where asn=#{ix[0]};"
		res=$peer_db.execute(req)
		if res[0][0]<1
			get_asn_prefixes(ix[0])
		end
	end
end
