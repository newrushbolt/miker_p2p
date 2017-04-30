def make_peer_list(conn_id)
	$return_data={}
	# if args.count < 1
		# $err_logger.error "Not enough arguments"
		# $err_logger.error args.to_s
		# $return_data["Error"]="Not enough arguments"
		# return JSON.generate($return_data)
	# end
	#	$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)

	$current_peer={}
	$current_peer["conn_id"]=conn_id
	channel_id=get_channel_id($current_peer["conn_id"])
	if channel_id == nil
		return nil
	end
	$current_peer["channel_id"]=channel_id
	$return_data={"conn_id" => $current_peer["conn_id"], "channel_id" => $current_peer["channel_id"],"peer_list" => []}
	$ignored_peers=[]
	$peers_lack=false
	$peers_required=10
	$peers_left=$peers_required

	begin
		req="select count(conn_id) as webrtc_count from #{$p2p_db_state_table} where conn_id <> \"#{$current_peer["conn_id"]}\" and channel_id = \"#{$current_peer["channel_id"]}\";"
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
		req="select conn_id,channel_id,gg_id,last_update,inet_ntoa(ip) as ip,inet_ntoa(network) as network,inet_ntoa(netmask) as netmask,asn,country,region from #{$p2p_db_state_table} where conn_id = \"#{$current_peer["conn_id"]}\";"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
	rescue => e
		$err_logger.error "Error while geting peer info"
		$err_logger.error e.to_s
	end

	if ! res.any?
		$return_data["Error"] = "Doesn't have this peer info (yet?)"
		$err_logger.warn "Doesn't have this peer info: #{$current_peer["conn_id"]}"
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

	$err_logger.debug "Peer: #{$current_peer}"

	$err_logger.debug "Getting overloaded peers"
	overloaded_peers=get_overloaded_peers($current_peer["channel_id"])
	$err_logger.debug "Got overloaded peers:\n#{overloaded_peers}"
	$ignored_peers=$ignored_peers | overloaded_peers

	$err_logger.debug "Getting droppy peers"
	droppy_peers=get_droppy_peers($current_peer["channel_id"])
	$err_logger.debug "Got droppy_peers peers:\n#{droppy_peers}"
	$ignored_peers=$ignored_peers | droppy_peers
	
	$err_logger.debug "Network peers, ignoring: #{$ignored_peers.to_s}"
	network_peers=get_network_peers($peers_left + $ignored_peers.count)
	if network_peers.any?
	    network_peers.each do |network_peer|
		peer_line={ :"#{network_peer["conn_id"]}" => "network" }
		$return_data["peer_list"].push(peer_line)
		$ignored_peers.push(network_peer["conn_id"])
		if $return_data["peer_list"].count >= $peers_required
		    break
		end
	    end
	end
	if enough_peers?
		return end_of_story($return_data)
	end

	$err_logger.debug "ASN peers, ignoring: #{$ignored_peers.to_s}"
	asn_peers=get_asn_peers($peers_left + $ignored_peers.count)
	if asn_peers.any?
	    asn_peers.each do |asn_peer|
		if ! $ignored_peers.include?(asn_peer["conn_id"])
		    peer_line={ :"#{asn_peer["conn_id"]}" => "asn" }
		    $return_data["peer_list"].push(peer_line)
		    $ignored_peers.push(asn_peer["conn_id"])
		    if $return_data["peer_list"].count >= $peers_required
			break
		    end
		end
	    end
	end
	if enough_peers?
	    return end_of_story($return_data)
	end

	$err_logger.debug "City peers, ignoring: #{$ignored_peers.to_s}"
	city_peers=get_city_peers($peers_left + $ignored_peers.count)
	if city_peers and city_peers.any?
	    city_peers.each do |city_peer|
		if ! $ignored_peers.include?(city_peer["conn_id"])
		    peer_line={ :"#{city_peer["conn_id"]}" => "city" }
		    $return_data["peer_list"].push(peer_line)
		    $ignored_peers.push(city_peer["conn_id"])
		    if $return_data["peer_list"].count >= $peers_required
			break
		    end
		end
	    end
	end
	if enough_peers?
		return end_of_story($return_data)
	end
	
	$err_logger.debug "region peers, ignoring: #{$ignored_peers.to_s}"
	region_peers=get_region_peers($peers_left + $ignored_peers.count)
	if region_peers and region_peers.any?
	    region_peers.each do |region_peer|
		if ! $ignored_peers.include?(region_peer["conn_id"])
		    peer_line={ :"#{region_peer["conn_id"]}" => "region" }
		    $return_data["peer_list"].push(peer_line)
		    $ignored_peers.push(region_peer["conn_id"])
		    if $return_data["peer_list"].count >= $peers_required
			break
		    end
		end
	    end
	end
	if enough_peers?
		return end_of_story($return_data)
	end
	
	$err_logger.debug "country peers, ignoring: #{$ignored_peers.to_s}"
	country_peers=get_country_peers($peers_left + $ignored_peers.count)
	if country_peers and country_peers.any?
	    country_peers.each do |country_peer|
		if ! $ignored_peers.include?(country_peer["conn_id"])
		    peer_line={ :"#{country_peer["conn_id"]}" => "country" }
		    $return_data["peer_list"].push(peer_line)
		    $ignored_peers.push(country_peer["conn_id"])
		    if $return_data["peer_list"].count >= $peers_required
			break
		    end
		end
	    end
	end
	if enough_peers?
		return end_of_story($return_data)
	end

	$err_logger.debug "Random peers, ignoring: #{$ignored_peers.to_s}"
	random_peers=get_random_peers($peers_left + $ignored_peers.count)
	if random_peers.any?
	    random_peers.each do |random_peer|
		if ! $ignored_peers.include?(random_peer["conn_id"])
		    peer_line={ :"#{random_peer["conn_id"]}" => "random" }
		    $return_data["peer_list"].push(peer_line)
		    $ignored_peers.push(random_peer["conn_id"])
		    if $return_data["peer_list"].count >= $peers_required
			break
		    end
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
    #$p2p_db_client.close
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
	req="select conn_id from #{$p2p_db_state_table} where channel_id = \"#{$current_peer["channel_id"]}\" and conn_id <> \"#{$current_peer["conn_id"]}\" limit #{peer_count};"
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
	req="select conn_id from #{$p2p_db_state_table} where network=inet_aton(\"#{$current_peer["network"]}\") and netmask=inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and conn_id <> \"#{$current_peer["conn_id"]}\" limit #{peer_count};"
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
	req="select conn_id from #{$p2p_db_state_table} where asn=#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and conn_id <> \"#{$current_peer["conn_id"]}\" limit #{peer_count};"
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
    if $current_peer["city"] and ! $current_peer["city"].nil?
	begin
	    req="select conn_id from #{$p2p_db_state_table} where city=\"#{$current_peer["city"]}\" and asn<>#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and conn_id <> \"#{$current_peer["conn_id"]}\" limit #{peer_count};"
	    $err_logger.debug req
	    res=$p2p_db_client.query(req)
	rescue  => e
    	    $err_logger.error "Error while geting city peers"
	    $err_logger.error e.to_s
    	    return nil
        end
	return res
    else
        $err_logger.warn "Peer #{$current_peer["conn_id"]} doesnt have correct city info"
        return nil
    end
end

def get_overloaded_peers(channel_id)
    result=[]
    begin
	req="select conn_id from #{$p2p_db_state_table} where channel_id=\"#{channel_id}\" and (select count(distinct peer_conn_id) from #{$p2p_db_peer_load_table} where seed_conn_id=conn_id) > #{$seed_max_peers_5};"
	$err_logger.debug req
	res=$p2p_db_client.query(req)
    rescue  => e
        $err_logger.error "Error while getting oveloaded peers"
        $err_logger.error e.to_s
        return nil
    end
    res.each do |peer|
	result.push(peer["conn_id"])
    end
    return result
end

def get_droppy_peers(channel_id)
    result=[]
    begin
	req="select conn_id from #{$p2p_db_state_table} where channel_id=\"#{channel_id}\" and (select count(distinct peer_conn_id) from #{$p2p_db_bad_peer_table} where seed_conn_id=conn_id) > #{$seed_max_drops_30};"
	$err_logger.debug req
	res=$p2p_db_client.query(req)
    rescue  => e
        $err_logger.error "Error while getting oveloaded peers"
        $err_logger.error e.to_s
        return nil
    end
    res.each do |peer|
	result.push(peer["conn_id"])
    end
    return result
end

def get_region_peers(peer_count)
    if $current_peer["region"] and ! $current_peer["region"].nil?
	    city_logic=($current_peer["city"] and ! $current_peer["city"].nil?) ? "city <> \"#{$current_peer["city"]}\" and" : ""
		begin
			req="select conn_id from #{$p2p_db_state_table} where #{city_logic} region=\"#{$current_peer["region"]}\" and asn<>#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and conn_id <> \"#{$current_peer["conn_id"]}\" limit #{peer_count};"
			$err_logger.debug req
			res=$p2p_db_client.query(req)
		rescue  => e
    	    $err_logger.error "Error while geting region peers"
			$err_logger.error e.to_s
    	    return nil
        end
		return res
    else
        $err_logger.warn "Peer #{$current_peer["conn_id"]} doesnt have correct region info"
        return nil
    end
end

def get_country_peers(peer_count)
    if $current_peer["country"] and ! $current_peer["country"].nil?
	    city_logic=($current_peer["city"] and ! $current_peer["city"].nil?) ? "city <> \"#{$current_peer["city"]}\" and" : ""
	    region_logic=($current_peer["region"] and ! $current_peer["region"].nil?) ? "region <> \"#{$current_peer["region"]}\" and" : ""
		begin
			req="select conn_id from #{$p2p_db_state_table} where #{city_logic} #{region_logic} country=\"#{$current_peer["country"]}\" and asn<>#{$current_peer["asn"]} and network<>inet_aton(\"#{$current_peer["network"]}\") and netmask<>inet_aton(\"#{$current_peer["netmask"]}\") and channel_id = \"#{$current_peer["channel_id"]}\" and conn_id <> \"#{$current_peer["conn_id"]}\" limit #{peer_count};"
			$err_logger.debug req
			res=$p2p_db_client.query(req)
		rescue  => e
    	    $err_logger.error "Error while geting country peers"
			$err_logger.error e.to_s
    	    return nil
        end
		return res
    else
        $err_logger.warn "Peer #{$current_peer["conn_id"]} doesnt have correct region info"
        return nil
    end
end

def get_channel_id(conn_id)
	begin
		$err_logger.debug "Getting channel id for peer: #{conn_id}"
		req="select channel_id from #{$p2p_db_state_table} where conn_id=\"#{conn_id}\" order by last_update desc;"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
	rescue  => e
		$err_logger.error "Error while geting channel id"
		$err_logger.error e.to_s
		return nil
	end
	if res.any?
		channel_id=res.first["channel_id"]
		$err_logger.debug "Got channel id for peer #{conn_id} : #{channel_id}"
		return channel_id
	else
		$err_logger.warn "Got no info for peer #{conn_id} : #{channel_id}"
		return nil
	end
end
