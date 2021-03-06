﻿require "#{File.expand_path(File.dirname(__FILE__))}/lib/worker.lib.rb"

class Slow_online_peer_worker < Common_worker

	private
	def update_peers_info(peer)
		begin
			req="select * from #{$p2p_db_state_table} where conn_id = \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
			res=@p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in SQL request for #{peer["conn_id"]}"
			$err_logger.error e.to_s
			$err_logger.error req
			return false
		end
		$err_logger.debug "Base got any peer info? #{res.any?.to_s}"
		peer["timestamp"]=peer["timestamp"].to_i
		if res.any?
			begin
				req="update #{$p2p_db_state_table} set last_update = \"#{peer["timestamp"]}\" where conn_id= \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
				res=@p2p_db_client.query(req)
				return true
			rescue  => e
				$err_logger.error "Error in DB update for #{peer["conn_id"]}"
				$err_logger.error e.to_s
				$err_logger.error req
				$err_logger.error peer
				return false
			end
		else
			aton_info=@slow_whois.get_ip_route(peer["ip"])
		end
		if ! aton_info or aton_info.nil? or !(aton_info["network"] and aton_info["netmask"] and aton_info["asn"])
			$err_logger.error "IP info for #{peer["ip"]} doesn't have enought info, only this:"
			$err_logger.error aton_info.to_s
			return false
		end
		peer["network"]=aton_info["network"]
		peer["netmask"]=aton_info["netmask"]
		peer["asn"]=aton_info["asn"]
		
		$err_logger.debug "Getting GeoIP info"
		begin
			geo_info=@geocity_client.city(peer["ip"])
		rescue  => e
			$err_logger.warn "Error in GeoIP for #{peer["ip"]}"
			$err_logger.warn e.to_s
		end
		
		if geo_info and geo_info.country_code3
			peer["country"]=geo_info.country_code3
		else
			$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have country_code3 info"
		end
		if geo_info and geo_info.real_region_name
			peer["region"]=geo_info.real_region_name
		else
			$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have real_region_name info"
		end
		if geo_info and geo_info.city_name
			peer["city"]=geo_info.city_name
		else
			$err_logger.warn "GeoIP for #{peer["ip"]} doesn't have city_name info"
		end

		$err_logger.debug "Updating peer_info in SQL"
		begin
			req="insert into #{$p2p_db_state_table} values (\"#{peer["conn_id"]}\",\"#{peer["channel_id"]}\",\"#{peer["gg_id"]}\",#{peer["timestamp"]}, INET_ATON(\"#{peer["ip"]}\"),INET_ATON(\"#{peer["network"]}\"),INET_ATON(\"#{peer["netmask"]}\"),#{peer["asn"]},\"#{peer["country"]}\",\"#{peer["region"]}\",\"#{peer["city"]}\") ON DUPLICATE KEY UPDATE channel_id=\"#{peer["channel_id"]}\";"
			res=@p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in SQL insert for #{peer["conn_id"]}"
			$err_logger.error peer
			$err_logger.error e.to_s
			$err_logger.error req
			return false
		end
		aff=@p2p_db_client.affected_rows
		$err_logger.debug "#{aff} rows affected"
		if aff > 0
			return true
		else
			return false
		end
	end

	public
	def run
		while true
			@bunny_workers["slow_online_peers"].subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
				peer=JSON.parse(body)
				peer["timestamp"]=Time.now.to_i()
				if @validator.v_conn_id(peer["conn_id"]) and @validator.v_channel_id(peer["channel_id"]) and @validator.v_gg_id(peer["gg_id"]) and @validator.v_ip(peer["ip"]) and @validator.v_ts(peer["timestamp"])
					if update_peers_info(peer) == true
						$err_logger.info "Peer #{peer["conn_id"]} parsed successfull"
						cnt_up("success")
					else
						req="insert into ip_bad_peers values (\"#{peer["conn_id"]}\",\"#{peer["channel_id"]}\",\"#{peer["gg_id"]}\",#{Time.now.to_i},INET_ATON(\"#{peer["ip"]}\")) ON DUPLICATE KEY UPDATE last_update=\"#{Time.now.to_i}\";"
						res=@p2p_db_client.query(req)
						$err_logger.warn "Parsing peer #{peer["conn_id"]} failed"
						cnt_up("failed")
					end
				else
					$err_logger.error "Got incorrect peer:\n#{peer}"
					cnt_up("failed")
				end
				@rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
			end
		end
	end
	
end

while true
	begin
		current_worker=nil
	rescue => e
		$err_logger.info "Error in class cleanup"
		$err_logger.info e.to_s
	end
	begin
		current_worker=Slow_online_peer_worker.new(\
		worker_id: ARGV[0], worker_log_level: ARGV[1], slow_whois_client: true,\
		bunny_queues: ["slow_online_peers"], geocity_client: true)
		current_worker.run
	rescue => e
		$err_logger.error "Error in main module,restarting the class"
		$err_logger.error e.to_s
	end
	sleep($worker_restart_interval)
end