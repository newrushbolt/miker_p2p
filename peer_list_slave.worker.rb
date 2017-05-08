require "#{File.expand_path(File.dirname(__FILE__))}/lib/make_peer_list.lib.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/lib/worker.lib.rb"

class Peer_list_slave_worker < Common_worker

	private
	def add_peer_list_to_db(list_json)
		list_raw=JSON.parse(list_json)
		begin
			list_encoded=@p2p_db_client.escape(list_json)
			db_req="insert into #{$p2p_db_peer_lists_table} (conn_id,ts,peer_list) values (\"#{list_raw["conn_id"]}\",\"#{Time.now.to_i}\",\"#{list_encoded}\") ON DUPLICATE KEY UPDATE ts=VALUES(ts),peer_list=VALUES(peer_list);"
			$err_logger.debug "DB req:#{db_req}"
			db_res=@p2p_db_client.query(db_req)
			$err_logger.debug "DB resp:#{db_res}"
			cnt_up("success")
		rescue => e_main
			$err_logger.error "Cannot add peer list to DB"
			$err_logger.error e_main.to_s
			cnt_up("failed")
		end
	end

	public
	def run
		while true
			@bunny_workers["peer_lists_tasks"].subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
				$err_logger.debug "Got task for peer #{body}"
				resp=make_peer_list(body.to_s)
				$err_logger.debug "Got peer_list: #{resp}"
				if resp!=nil
					add_peer_list_to_db(resp)
				end
				@rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
			end
		end
	end

end

current_worker=Peer_list_slave_worker.new(worker_id: ARGV[0],worker_log_level: ARGV[1],bunny_queues: ["peer_lists_tasks"])
current_worker.run
