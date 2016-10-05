def make_peer_list(args)
	$return_data={}
	if args.count <3
		$err_logger.error "Not enough arguments, got only"
		$err_logger.error args.to_s
		$return_data["Error"]="Not enough arguments"
		return JSON.generate($return_data)
	end

	$current_peer={}
	$current_peer["webrtc_id"]=args[0]
	$current_peer["channel_id"]=args[1]
	$return_data={"webrtc_id" => $current_peer["webrtc_id"], "channel_id" => $current_peer["channel_id"],"peer_list" => []}
	$ignored_peers=[]
	$peers_lack=false
	$peers_required=args[2].to_i
	$peers_left=$peers_required

	$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)

	begin
		req="select count(webrtc_id) as webrtc_count from #{$p2p_db_state_table} where webrtc_id <> \"#{$current_peer["webrtc_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\";"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
	rescue => e
		$err_logger.error "Error while counting peers in SQL"
		$err_logger.error e.to_s
	end
	if res.first["webrtc_count"] < $peers_required
		$peers_lack=true
		$err_logger.warn "SQL doesn't contain enought peers"
	end
	
	begin
		req="select webrtc_id,channel_id,gg_id,last_update,inet_ntoa(ip) as ip,inet_ntoa(network) as network,inet_ntoa(netmask) as netmask,asn,country,region from #{$p2p_db_state_table} where webrtc_id = \"#{$current_peer["webrtc_id"]}\";"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
	rescue => e
		$err_logger.error "Error while geting peer info"
		$err_logger.error e.to_s
	end

	if ! res.any?
		$return_data["Error"] = "Doesn't have this peer info (yet?)"
		$err_logger.error "Doesn't have this peer info: #{$current_peer["webrtc_id"]}"
		$err_logger.error res.inspect
		return end_of_story($return_data)
	end

	#Need to deal with enum items counting,later
	# if res.count == 0
		# $return_data["Error"]="Doesn't have this peer info (yet?)"}
		# $err_logger.error res.each
		# return JSON.generate($return_data)
	# elsif
		# $return_data["Warning"]="DB contains several this peers, need to cleanup|fix"
		# $err_logger.error res.each
		# return JSON.generate($return_data)
	# end
		
	peer_res=res.first
	$current_peer["ip"]=peer_res["ip"]
	$current_peer["network"]=peer_res["network"]
	$current_peer["netmask"]=peer_res["netmask"]
	$current_peer["last_online"]=peer_res["last_online"]
	$current_peer["asn"]=peer_res["asn"]
	$current_peer["country"]=peer_res["country"]
	$current_peer["city"]=peer_res["city"]
	$current_peer["region"]=peer_res["region"]

	$err_logger.debug "Network peers, ignoring: #{$ignored_peers.to_s}"
	network_peers=get_network_peers($peers_left)
	if network_peers.any?
		network_peers.each do |network_peer|
			peer_line=[network_peer["webrtc_id"],"network"]
			$return_data["peer_list"].push(peer_line)
			$ignored_peers.push(network_peer["webrtc_id"])
		end
	end
	if enough_peers?
		return end_of_story($return_data)
	end

	$err_logger.debug "ASN peers, ignoring: #{$ignored_peers.to_s}"
	asn_peers=get_asn_peers($peers_left)
	if asn_peers.any?
	    asn_peers.each do |asn_peer|
		if ! $ignored_peers.include?(asn_peer["webrtc_id"])
		    peer_line=[asn_peer["webrtc_id"],"asn"]
		    $return_data["peer_list"].push(peer_line)
		    $ignored_peers.push(asn_peer["webrtc_id"])
		end
	    end
	end
	if enough_peers?
		return end_of_story($return_data)
	end

	$err_logger.debug "City peers, ignoring: #{$ignored_peers.to_s}"
	city_peers=get_city_peers($peers_left)
	if city_peers.any?
		city_peers.each do |city_peer|
			if ! $ignored_peers.include?(city_peer["webrtc_id"])
				peer_line=[city_peer["webrtc_id"],"city"]
				$return_data["peer_list"].push(peer_line)
				$ignored_peers.push(city_peer["webrtc_id"])
			end
		end
	end
	if enough_peers?
		return end_of_story($return_data)
	end

	$err_logger.debug "Random peers, ignoring: #{$ignored_peers.to_s}"
	random_peers=get_random_peers($peers_left)
	if random_peers.any?
		random_peers.each do |random_peer|
			if ! $ignored_peers.include?(random_peer["webrtc_id"])
				peer_line=[random_peer["webrtc_id"],"random"]
				$return_data["peer_list"].push(peer_line)
				$ignored_peers.push(random_peer["webrtc_id"])
			end
		end
	end
	
	if enough_peers?
		return end_of_story($return_data)
	else
		$return_data["Warning"]="Not enough peers grabbed"
		return end_of_story($return_data)
	end
end

def end_of_story(data)
	$p2p_db_client.close
	return JSON.generate(data)
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
		$err_logger.debug req
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
		$err_logger.debug req
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
		$err_logger.debug req
		res=$p2p_db_client.query(req)
    rescue  => e
        $err_logger.error "Error while geting city peers"
        $err_logger.error e.to_s
        return nil
    end
	return res
end
