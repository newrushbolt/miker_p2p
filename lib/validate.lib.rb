class Webrtc_validator

	def initialize
		@private_ip_nets=[]
		$private_nets.each do |net|
			@private_ip_nets.push(IPAddr.new(net))
		end
	end

	def v_webrtc_id(webrtc_id)
		webrtc_id_true=webrtc_id.to_s.encode('utf-8', :invalid => :replace, :undef => :replace)
		if webrtc_id.nil? or webrtc_id_true != webrtc_id
			return false
		end
		if webrtc_id.match(/[1-9]{1}\:[0-9a-z]{9}/).to_s == webrtc_id
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
		if channel_id.match(/[0-9a-zA-Z]{1,14}(_[0-9a-zA-Z]{1,14}){2}/).to_s == channel_id
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
	
	def v_ts(ts)
		begin
			ts_obj=Time.at(ts.to_i/1000)
			if ts_obj.to_i == (ts.to_i/1000) and (Time.now - ts_obj).to_i.abs < 600
				return true
			else
				return false
			end
		rescue => e_cor
			return false
		end
	end
end
