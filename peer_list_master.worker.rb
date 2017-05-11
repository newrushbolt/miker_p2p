require "#{File.expand_path(File.dirname(__FILE__))}/lib/worker.lib.rb"

class Peer_list_master_worker < Common_worker

	private
	def get_absent_peers()
		begin
			req="select p.conn_id from peer_state p where (select count(conn_id) from peer_lists where conn_id = p.conn_id) = 0;"
			$err_logger.debug req
			res=@p2p_db_client.query(req)
			$err_logger.debug "Returning absent peers data: #{res.to_a}"
			$err_logger.info "Returning #{res.count} absent peers"
			local_absent_peers=res.to_a.map{ |item| item.values }.flatten
			$err_logger.debug "Returning absent peers: #{local_absent_peers}"
			return local_absent_peers
		rescue => e
			$err_logger.error "Error in DB request for absent peers"
			$err_logger.error e.to_s
			$err_logger.error req
			return []
		end
	end

	def get_outdated_peers(period)
		begin
			req="select p.conn_id from peer_state p where (select count(conn_id) from peer_lists where conn_id = p.conn_id and ts < (UNIX_TIMESTAMP(NOW()) - #{period})) = 1 ;"
			$err_logger.debug req
			res=@p2p_db_client.query(req)
			$err_logger.debug "Returning outdated peers data: #{res.to_a}"
			$err_logger.info "Returning #{res.count} outdated peers"
			local_outdated_peers=res.to_a.map{ |item| item.values }.flatten
			$err_logger.debug "Returning outdated peers: #{local_outdated_peers}"
			return local_outdated_peers
		rescue => e
			$err_logger.error "Error in DB request for outdated peers"
			$err_logger.error e.to_s
			$err_logger.error req
			return []
		end
	end

	def add_lists_tasks(tasks)
		$err_logger.info "Got #{tasks.count} tasks to add"
		$err_logger.debug "Got tasks to add: #{tasks}"
		tasks.each do |task|
			begin
				$err_logger.debug "Adding task: #{task}"
				@bunny_workers["peer_lists_tasks"].publish(task.to_s, :routing_key => @bunny_workers["peer_lists_tasks"].name, :persistent => false)
				cnt_up("success")
			rescue => e_main
				$err_logger.error "Error while adding task to RabbitMQ: #{task}"
				$err_logger.error e_main.to_s
				cnt_up("failed")
			end
		end
	end

	public
	def run
		while true
			absent_peers=get_absent_peers
			outdated_peers=get_outdated_peers($peer_list_outdate_period)
			add_lists_tasks(absent_peers + outdated_peers)
			sleep(30)
		end
	end

end

while true
	begin
		current_worker=Peer_list_master_worker.new(worker_id: ARGV[0],worker_log_level: ARGV[1],bunny_queues: ["peer_lists_tasks"])
		current_worker.run
	rescue => e
		$err_logger.error "Error in main module,restarting the class"
		$err_logger.error e.to_s
	end
	sleep($worker_restart_interval)
end
