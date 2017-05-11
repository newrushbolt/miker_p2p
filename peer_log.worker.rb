require "#{File.expand_path(File.dirname(__FILE__))}/lib/worker.lib.rb"

class Peer_log_worker < Common_worker
	private

	def db_got_peer(peer)
		begin
			req="select * from #{$p2p_db_state_table} where conn_id = \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
			$err_logger.debug req
			res=@p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in SQL request for #{peer["conn_id"]}"
			$err_logger.error e.to_s
			$err_logger.error req
			return false
		end
		$err_logger.debug "Base got any peer info? #{res.any?.to_s}"
		if res.any?
			return true
		end
		return false
	end

	public
	def run
		while true
			@bunny_workers["peer_log"].subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
				peer=JSON.parse(body)
				$err_logger.debug "Got log:\n#{peer}"
				if @validator.v_peer_log_entry(peer)
					$err_logger.debug "Finding seed in peer_state db"
					if db_got_peer(peer)
						begin
							req="update #{$p2p_db_state_table} set last_update = \"#{peer["timestamp"]}\" where conn_id= \"#{peer["conn_id"]}\" and channel_id = \"#{peer["channel_id"]}\";"
							res=@p2p_db_client.query(req)
						rescue  => e
							$err_logger.error "Error in DB update for #{peer["conn_id"]}"
							$err_logger.error e.to_s
							$err_logger.error req
							$err_logger.error peer
						end
					else
						$err_logger.info "Peer #{peer["conn_id"]} doesnt exist in peer_state db, adding to common queue"
						online_peer={}
						online_peer["conn_id"]=peer["conn_id"]
						online_peer["gg_id"]=peer["gg_id"]
						online_peer["channel_id"]=peer["channel_id"]
						online_peer["ip"]=peer["ip"]
						online_peer["timestamp"]=peer["timestamp"]
						@bunny_workers["common_online_peers"].publish(JSON.generate(online_peer), :routing_key => @bunny_workers["common_online_peers"].name, :persistent => false)
					end
					$err_logger.debug "Updating good_peer in SQL"
					good_peer=peer["good_peer"]
					if @validator.v_good_peer(good_peer)
						begin
							req="insert ignore into #{$p2p_db_peer_load_table} values (\"#{good_peer["Conn_id"]}\",#{peer["timestamp"]},\"#{peer["conn_id"]}\",#{good_peer["P2p"]},#{good_peer["Ltime"]});"
							$err_logger.debug req
							res=@p2p_db_client.query(req)
						rescue => e
							$err_logger.error "Error in SQL insert for good_peer: #{good_peer}"
							$err_logger.error peer
							$err_logger.error req
							$err_logger.error e.to_s
						end
						aff=@p2p_db_client.affected_rows
						$err_logger.debug "#{aff} rows affected"
					end
					$err_logger.debug "Updating bad_peers in SQL"
					bad_peer=peer["bad_peer"]
					if @validator.v_conn_id(bad_peer["Conn_id"])
						begin
							req="insert ignore into #{$p2p_db_bad_peer_table} values (\"#{bad_peer["Conn_id"]}\",#{peer["timestamp"].to_i},\"#{peer["conn_id"]}\");"
							$err_logger.debug req
							res=@p2p_db_client.query(req)
							aff=@p2p_db_client.affected_rows
						rescue => e
							$err_logger.error "Error in SQL insert for bad_peer: #{bad_peer}"
							$err_logger.error peer
							$err_logger.error req
							$err_logger.error e.to_s
						end
						$err_logger.debug "#{aff} rows affected"
					end
					cnt_up("success")
				else
					cnt_up("failed")
				end
				@rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
			end
		end
	end

end

while true
	begin
		current_worker=Peer_log_worker.new(worker_id: ARGV[0],worker_log_level: ARGV[1],bunny_queues: ["common_online_peers","peer_log"])
		current_worker.run
	rescue => e
		$err_logger.error "Error in main module,restarting the class"
		$err_logger.error e.to_s
	end
	sleep($worker_restart_interval)
end
