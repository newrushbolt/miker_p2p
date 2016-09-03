require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'mysql2'
require 'mongo'
require 'json'

$err_logger=Logger.new("#{$log_dir}/make_peer_list.lib.err.log")


def make_peer_list(args)

	if args.count <3
		$err_logger.error 'Peer ID, channel ID and neighbors count needed, like this:'
		$err_logger.error '>make_peer_list.worker.rb 8ecdc46f-1723-4474-b5ec-145e178cfb82 1231fsa2 10'
		exit 1
	end

	$current_peer={}
	$current_peer["webrtc_id"]=args[0]
	$current_peer["channel_id"]=args[1]
	$return_data={"webrtc_id" => $current_peer["webrtc_id"], "channel_id" => $current_peer["channel_id"],"peer_list" => []}
	$peers_required=args[2].to_i
	$peers_left=$peers_required

	Mongo::Logger.logger.level = Logger::WARN
	mongo_client = client = Mongo::Client.new($mongo_url)
	$webrtc_raw_peers=mongo_client[:raw_peers]

	$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)

	begin
		req="select count(webrtc_id) as webrtc_count from #{$p2p_db_state_table} where webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\";"
		res=$p2p_db_client.query(req)
	rescue => e
		$err_logger.error "Error while counting peers in DB"
		$err_logger.error e.to_s
	end
	if res.first["webrtc_count"] < $peers_required
		$peers_lack=true
		$err_logger.error "DB doesn't contain enought peers"
	end
	
	begin
		req="select webrtc_id,channel_id,gg_id,last_update,inet_ntoa(ip) as ip,inet_ntoa(network) as network,inet_ntoa(netmask) as netmask,asn,country,region from #{$p2p_db_state_table} where webrtc_id = \"#{$current_peer["webrtc_id"]}\";"
		res=$p2p_db_client.query(req)
	rescue => e
		$err_logger.error "Error while geting peer info"
		$err_logger.error e.to_s
	end
	
	if res.count == 0
		$return_data={"Error" => "Doesn't have this peer info (yet?)"}
		$err_logger.error res.to_h	
		return JSON.generate($return_data)
	elsif
		$return_data["Warning"]="DB contains several this peers, need to cleanup|fix"
		$err_logger.error res.to_h
		return JSON.generate($return_data)
	end
		
	peer_res=res.first
	$current_peer["ip"]=peer_res["ip"]
	$current_peer["network"]=peer_res["network"]
	$current_peer["netmask"]=peer_res["netmask"]
	$current_peer["last_online"]=peer_res["last_online"]
	$current_peer["asn"]=peer_res["asn"]
	$current_peer["country"]=peer_res["country"]
	$current_peer["city"]=peer_res["city"]
	$current_peer["region"]=peer_res["region"]

	network_peers=get_network_peers($peers_left)
	if network_peers.any?
		network_peers.each do |network_peer|
			peer_line=[network_peer[0],"network"]
			$return_data["peer_list"].push(peer_line)
		end
	end

	if enough_peers?
		return JSON.generate($return_data)
	end
	asn_peers=get_asn_peers($peers_left)
	if asn_peers.any?
		asn_peers.each do |asn_peer|
			peer_line=[asn_peer[0],"asn"]
			$return_data["peer_list"].push(peer_line)
		end
	end

	if enough_peers?
		return JSON.generate($return_data)
	end
	city_peers=get_city_peers($peers_left)
	if city_peers.any?
		city_peers.each do |city_peer|
			peer_line=[city_peer[0],"city"]
			$return_data["peer_list"].push(peer_line)
		end
	end

	if enough_peers?
		return JSON.generate($return_data)
	end
	random_peers=get_random_peers($peers_left)
	if random_peers.any?
		random_peers.each do |random_peer|
			peer_line=[random_peer[0],"random"]
			$return_data["peer_list"].push(peer_line)
		end
	end
	
	if enough_peers?
		return JSON.generate($return_data)
	else
		$return_data["Warning"]="Not enough peers grabbed"
		return JSON.generate($return_data)
	end
end
	
def enough_peers?
	if $return_data["peer_list"].count >= $peers_required
		return true
	else
		$peers_left = $peers_required - $return_data["peer_list"].count 
		return false
	end
end

def remove_bad_peers(peer_list)
	if ! peer_list.any?
		return nil
	end
end
	
def get_random_peers(peer_count)
	begin
	req="select webrtc_id from #{$p2p_db_state_table} where channel_id = \"#{$current_peer["channel_id"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"		
	res=$p2p_db_client.query(req)
    rescue => e
        $err_logger.error "Error while geting peers for channel #{$current_peer["channel_id"]}"
        $err_logger.error e.to_s
        return nil
    end
	return res
end

def get_network_peers(peer_count)
	begin
		req="select webrtc_id from #{$p2p_db_state_table} where network=inet_aton(\"#{$current_peer["network"]}\") and netmask=inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"
		res=$p2p_db_client.query(req)
    rescue  => e
        $err_logger.error "Error while geting network peers"
        $err_logger.error e.to_s
        return nil
    end
	return res
end

def get_asn_peers(peer_count)
	begin
		req="select webrtc_id from #{$p2p_db_state_table} where asn=#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"
		res=$p2p_db_client.query(req)
    rescue  => e
        $err_logger.error "Error while geting ASN peers"
        $err_logger.error e.to_s
        return nil
    end
	return res
end

def get_city_peers(peer_count)
	begin
		req="select webrtc_id from #{$p2p_db_state_table} where city=\"#{$current_peer["city"]}\" and asn<>#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and webrtc_id <> \"#{$current_peer["webrtc_id"]}\" limit #{peer_count};"
		res=$p2p_db_client.query(req)
    rescue  => e
        $err_logger.error "Error while geting city peers"
        $err_logger.error e.to_s
        return nil
    end
	return res
end
