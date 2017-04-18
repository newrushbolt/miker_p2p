def cnt_up(worker,type)
	begin
		req="update #{$p2p_db_counters_table} set count = count + 1 where worker=\"#{worker}\" and type=\"#{type}\";"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
		return true
	rescue  => e
		$err_logger.error "Error in SQL counters update for #{worker} type #{type}"
		$err_logger.error req
		$err_logger.error e.to_s
		return false
	end
end

def cnt_init(worker)
	["failed","success","invalid"].each do |field|
		begin
			req="insert ignore into #{$p2p_db_counters_table} values (\"#{worker}\",\"#{field}\",0);"
			$err_logger.debug req
			res=$p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in SQL init counters #{worker} type #{field}"
			$err_logger.error req
			$err_logger.error e.to_s
		end
	end
end