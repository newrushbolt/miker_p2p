require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'json'

if ARGV.count <3
	STDERR.puts 'Peer ID, channel ID and neighbors count needed, like this:'
	STDERR.puts '>make_peer_list.worker.rb 8ecdc46f-1723-4474-b5ec-145e178cfb82 1231fsa2 10'
	exit 1
end

$current_peer={}
$current_peer["channel_id"]=ARGV[1]
$return_data={"webrtc_id" => $current_peer["webrtc_id"], "channel_id" => $current_peer["channel_id"],"peer_list" => []}
$peers_required=ARGV[2].to_i
$peers_lack=false
$peers_left=$peers_required

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
$webrtc_raw_peers=mongo_client[:raw_peers]

$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)

begin
	req="select count(webrtc_id) from #{$p2p_db_state_table} where webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\";"
	res=$p2p_db_client.query(req)
rescue => e
    STDERR.puts "Error while counting peers in DB"
    STDERR.puts e.to_s
end
if res[0][0] < $peers_required
	$peers_lack=true
	STDERR.puts "DB doesn't contain enought peers"
end

def enough_peers?
	if $return_data["peer_list"].count >= $peers_required
		puts JSON.generate($return_data)
		exit
	else
		$peers_left = $peers_required - $return_data["peer_list"].count 
		return nil
	end
end

def remove_bad_peers(peer_list)
	if ! peer_list.any?
		return nil
	end
end
	
def get_random_peers(peer_count)
	begin
	req="select webrtc_id from #{$p2p_db_state_table} where webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\" limit #{peer_count};"		
	res=$p2p_db_client.query(req)
    rescue => e
        STDERR.puts "Error while geting peers for channel #{$current_peer["channel_id"]}"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

def get_network_peers(peer_count)
	begin
		req="select webrtc_id from #{$p2p_db_state_table} where network=inet_aton(\"#{$current_peer["network"]}\") and netmask=inet_aton(\"#{$current_peer["netmask"]}\") and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"
		res=$p2p_db_client.query(req)
    rescue  => e
        STDERR.puts "Error while geting network peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

def get_asn_peers(peer_count)
	begin
		req="select webrtc_id from #{$p2p_db_state_table} where asn=#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"
		res=$p2p_db_client.query(req)
    rescue  => e
        STDERR.puts "Error while geting ASN peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

def get_city_peers(peer_count)
	begin
		req="select webrtc_id from #{$p2p_db_state_table} where city=\"#{$current_peer["city"]}\" and asn<>#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and webrtc_id <>\"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"
		res=$p2p_db_client.query(req)
    rescue  => e
        STDERR.puts "Error while geting city peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

begin
	req="select webrtc_id,channel_id,gg_id,last_update,inet_ntoa(ip),inet_ntoa(network),inet_ntoa(netmask),asn,country,region from #{$p2p_db_state_table} where webrtc_id = \"#{$current_peer["webrtc_id"]}\";"
	res=$p2p_db_client.query(req)
rescue => e
    STDERR.puts "Error while geting peer info"
    STDERR.puts e.to_s
end

$current_peer["ip"]=res[0]["inet_ntoa(ip)"]
$current_peer["network"]=res[0]["inet_ntoa(network)"]
$current_peer["netmask"]=res[0]["inet_ntoa(netmask)"]
$current_peer["last_online"]=res[0]["last_online"]
$current_peer["asn"]=res[0]["asn"]
$current_peer["country"]=res[0]["country"]
$current_peer["city"]=res[0]["city"]
$current_peer["region"]=res[0]["region"]

network_peers=get_network_peers($peers_left)
if network_peers.any?
	network_peers.each do |network_peer|
		peer_line=[network_peer[0],"network"]
		$return_data["peer_list"].push(peer_line)
	end
end

enough_peers?
asn_peers=get_asn_peers($peers_left)
if asn_peers.any?
	asn_peers.each do |asn_peer|
		peer_line=[asn_peer[0],"asn"]
		$return_data["peer_list"].push(peer_line)
	end
end

enough_peers?
city_peers=get_city_peers($peers_left)
if city_peers.any?
	city_peers.each do |city_peer|
		peer_line=[city_peer[0],"city"]
		$return_data["peer_list"].push(peer_line)
	end
end

enough_peers?
random_peers=get_random_peers($peers_left)
if random_peers.any?
	random_peers.each do |random_peer|
		peer_line=[random_peer[0],"random"]
		$return_data["peer_list"].push(peer_line)
	end
end

if enough_peers?.nil?
	puts JSON.generate($return_data)
	exit
end 