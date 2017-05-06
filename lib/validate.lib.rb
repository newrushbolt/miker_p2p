class Webrtc_validator
private
	def is_pure_utf(input_string)
		pure_string=input_string.to_s.encode('utf-8', :invalid => :replace, :undef => :replace)
		if input_string.nil? or pure_string != input_string
			return false
		else
			return true
		end
	end

public
	def initialize
		@private_ip_nets=[]
		$private_nets.each do |net|
			@private_ip_nets.push(IPAddr.new(net))
		end
	end

	def v_good_peer(peer)
		$err_logger.debug "Running #{__method__}"
		fields=["Conn_id","P2p","Ltime"]
		$err_logger.debug peer
		if v_log_fields(peer,fields) and v_conn_id(peer["Conn_id"]) and v_ltime(peer["Ltime"]) and v_ltime(peer["P2p"])
			$err_logger.debug "Data #{peer} is VALID"
			return true
		end
		$err_logger.debug "Data #{peer} is INVALID"
		return false
	end

	def v_ltime(ltime)
		if ltime.to_i == ltime and ltime > 0
			$err_logger.debug "Data #{ltime} is VALID"
			return true
		end
		$err_logger.debug "Data #{ltime} is INVALID"
		return false
	end

	def v_peer_log_entry(peer)
		$err_logger.debug "Running #{__method__}"
		fields=["conn_id","gg_id","channel_id","timestamp","good_peer","bad_peer","ip"]
		if v_log_fields(peer,fields) and v_conn_id(peer["conn_id"]) and v_gg_id(peer["gg_id"]) and v_channel_id(peer["channel_id"]) and v_ts(peer["timestamp"]) and v_ip(peer["ip"])
			$err_logger.debug "Data #{peer} is VALID"
			return true
		end
		$err_logger.debug "Data #{peer} is INVALID"
		return false
	end
	
	def v_conn_id(conn_id)
		$err_logger.debug "Running #{__method__}"
		if is_pure_utf(conn_id) and conn_id.match(/[a-z0-9]*/).to_s == conn_id
			$err_logger.debug "Data #{conn_id} is VALID"
			return true
		end
		$err_logger.debug "Data #{conn_id} is INVALID"
		return false
	end

	def v_channel_id(channel_id)
		$err_logger.debug "Running #{__method__}"
		if is_pure_utf(channel_id) and channel_id.match(/.*/).to_s == channel_id
			$err_logger.debug "Data #{channel_id} is VALID"
			return true
		end
		$err_logger.debug "Data #{channel_id} is INVALID"
		return false
	end

	def v_gg_id(gg_id)
		$err_logger.debug "Running #{__method__}"
		if is_pure_utf(gg_id) and gg_id.match(/[0-9a-z]{8}(\-[0-9a-z]{4}){3}\-[0-9a-z]{12}/).to_s == gg_id
			return true
		end
		$err_logger.debug "Data #{gg_id} is INVALID"
		return false
	end

	def v_ip(ip)
		$err_logger.debug "Running #{__method__}"
		begin
			ip_obj=IPAddr.new(ip)
			@private_ip_nets.each do |net|
				if net.include?(ip)
					return false
				end
			end
			if ip_obj.to_s == ip
				return true
			else
				return false
			end
		rescue  => e_cor
			$err_logger.debug "Data #{ip} is INVALID"
			return false
		end
	end
	
	def v_log_fields(entry,fields)
	    return true
	    # $err_logger.debug "Got required fields: #{fields}"
		# if ! entry.to_a.count == fields.count
			# return false
		# end
		# fields.each do |field|
			# $err_logger.debug "Got field: #{field}"
			# $err_logger.debug "Field result: #{entry.has_key?(field).inspect}"
			# if ! entry[field]
				# return false
			# end
		# end
		# return true
	end
	
	def v_ts(ts)
	    return true
#		begin
#			ts_obj=Time.at(ts)
#			if ts_obj.to_i == ts and (Time.now - ts_obj).to_i.abs < 86400
#				return true
#			else
#				return false
#			end
#		rescue => e_cor
#			return false
#		end
	end
end
