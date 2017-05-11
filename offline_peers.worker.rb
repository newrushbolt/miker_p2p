require "#{File.expand_path(File.dirname(__FILE__))}/lib/worker.lib.rb"

class Offline_peers_worker < Common_worker

	private
	def remove_peer(peer)
		begin
			req="delete from #{$p2p_db_state_table} where conn_id = \"#{peer}\";"
			$err_logger.debug req
			res=@p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in SQL removal peer for #{peer}"
			$err_logger.error e.to_s
			$err_logger.error req
			return false
		end
		aff=@p2p_db_client.affected_rows
		$err_logger.debug "#{aff} rows affected"
		case aff
		when 1
			return true
		when 0
			return false
		else
			$err_logger.error "Removed more than 1 (#{afk}) peer for conn_id:#{peer}"
			return false
		end
	end

	def remove_list(peer)
		begin
			req="delete from #{$p2p_db_peer_lists_table} where conn_id = \"#{peer}\";"
			$err_logger.debug req
			res=@p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in SQL removal list for #{peer}"
			$err_logger.error e.to_s
			$err_logger.error req
			return false
		end
		aff=@p2p_db_client.affected_rows
		$err_logger.debug "#{aff} rows affected"
		case aff
		when 1
			return true
		when 0
			return false
		else
			$err_logger.error "Removed more than 1 (#{afk}) lists for conn_id:#{peer}"
			return false
		end
	end

	public
	def run
		while true
			@bunny_workers["offline_peers"].subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
				$err_logger.debug "Got info:\n #{body}"
				peer=JSON.parse(body)
				fields=["conn_id"]
				if @validator.v_log_fields(peer,fields) and @validator.v_conn_id(peer["conn_id"])
					if remove_peer(peer["conn_id"]) and remove_list(peer["conn_id"])
						$err_logger.info "Peer #{peer["conn_id"]} removed successfull"
						cnt_up("success")
					else
						$err_logger.warn "Peer #{peer["conn_id"]} removal failed"
						cnt_up("failed")
					end
				else
					$err_logger.error "Got incorrect peer:\n#{peer}"
					$err_logger.error "conn_id: #{$validator.v_conn_id(peer["conn_id"]).inspect}"
					cnt_up("failed")
				end
				@rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
			end
		end
	end

end

while true
	begin
		current_worker=Offline_peers_worker.new(worker_id: ARGV[0],worker_log_level: ARGV[1],bunny_queues: ["offline_peers"])
		current_worker.run
	rescue => e
		$err_logger.error "Error in main module,restarting the class"
		$err_logger.error e.to_s
	end
	sleep($worker_restart_interval)
end
