require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'sqlite3'
require 'json'

if ARGV.count <3
	STDERR.puts 'Peer ID, channel ID and neighbors count needed, like this:'
	STDERR.puts '>make_peer_list.worker.rb 8ecdc46f-1723-4474-b5ec-145e178cfb82 1231fsa2 10'
	exit 1
end

$current_peer={}
$current_peer["webrtc_id"]=ARGV[0]
$current_peer["channel_id"]=ARGV[1]
$return_data={"webrtc_id" => $current_peer["webrtc_id"], "channel_id" => $current_peer["channel_id"],"peer_list" => []}
$peers_required=ARGV[2].to_i
$peers_lack=false
$peers_left=$peers_required

$peer_db=SQLite3::Database.new($peer_db_file)

begin
	req="select count(webrtc_id) from #{$peer_state_table};"
	res=$peer_db.execute(req)
rescue  => e
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

def get_random_peers(peer_count)
	begin
		req="select webrtc_id from #{$peer_state_table} where channel_id = \"#{$current_peer["channel_id"]}\" webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"
		res=$peer_db.execute(req)
    rescue  => e
        STDERR.puts "Error while geting peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

def get_network_peers(peer_count)
	begin
		req="select webrtc_id from #{$peer_state_table} where network=\"#{$current_peer["network"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\" limit #{peer_count};"
		res=$peer_db.execute(req)
    rescue  => e
        STDERR.puts "Error while geting network peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

def get_asn_peers(peer_count)
	begin
		req="select webrtc_id from #{$peer_state_table} where asn=#{$current_peer["asn"]} and network<>\"#{$current_peer["network"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\" limit #{peer_count};"
		res=$peer_db.execute(req)
    rescue  => e
        STDERR.puts "Error while geting ASN peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

def get_city_peers(peer_count)
	begin
		req="select webrtc_id from #{$peer_state_table} where city=\"#{$current_peer["city"]}\" and asn<>#{$current_peer["asn"]} and network<>\"#{$current_peer["network"]}\" and webrtc_id <>\"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\" limit #{peer_count};"
		res=$peer_db.execute(req)
    rescue  => e
        STDERR.puts "Error while geting city peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

begin
	req="select * from #{$peer_state_table} where webrtc_id = \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\";"
	res=$peer_db.execute(req)
rescue => e
    STDERR.puts "Error while geting peer info"
    STDERR.puts e.to_s
end

$current_peer["ip"]=res[0][2]
$current_peer["network"]=res[0][4]
$current_peer["last_online"]=res[0][3]
$current_peer["netname"]=res[0][5]
$current_peer["asn"]=res[0][6]
$current_peer["country"]=res[0][7]
$current_peer["city"]=res[0][8]

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

enough_peers?.nil?.to_s