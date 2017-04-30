class Webrtc_validator

	def initialize
		@private_ip_nets=[]
		$private_nets.each do |net|
			@private_ip_nets.push(IPAddr.new(net))
		end
	end

	def v_conn_id(conn_id)
		conn_id_true=conn_id.to_s.encode('utf-8', :invalid => :replace, :undef => :replace)
		if conn_id.nil? or conn_id_true != conn_id
			return false
		end
		if conn_id.match(/[a-z0-9]*/).to_s == conn_id
			return true
		else
			return false
		end
	end

	def v_channel_id(channel_id)
		channel_id_true=channel_id.to_s.encode('utf-8', :invalid => :replace, :undef => :replace)
		if channel_id.nil? or channel_id_true != channel_id
			return false
		end
		if channel_id.match(/.*/).to_s == channel_id
			return true
		else
			return false
		end
	end

	def v_gg_id(gg_id)
		gg_id_true=gg_id.to_s.encode('utf-8', :invalid => :replace, :undef => :replace)
		if gg_id.nil? or gg_id_true != gg_id
			return false
		end
		if gg_id.match(/[0-9a-z]{8}(\-[0-9a-z]{4}){3}\-[0-9a-z]{12}/).to_s == gg_id
			return true
		else
			return false
		end
	end

	def v_ip(ip)
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
			return false
		end
	end
	
	def v_log_fields(entry,fields)
	    return true
	    $err_logger.debug "Got required fields: #{fields}"
		if ! entry.to_a.count == fields.count
			return false
		end
		fields.each do |field|
			$err_logger.debug "Got field: #{field}"
			$err_logger.debug "Field result: #{entry.has_key?(field).inspect}"
			if ! entry[field]
				return false
			end
		end
		return true
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
