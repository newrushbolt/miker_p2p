class Common_worker

	def initialize(worker_id: 1,worker_log_level: nil,p2p_db: true, whois_client: false, bunny_queues: [],geocity_client: false)
		require 'rubygems'
		require 'etc'
		require 'ipaddr'
		require 'json'
		require 'logger'
		i_name(worker_id)
		i_conf
		i_logger(worker_log_level)
		i_chuser
		i_validator
		if p2p_db then i_p2p_db end
		if whois_client then i_whois_client end
		if bunny_queues.any?
			@bunny_workers={}
			i_bunny(bunny_queues)
		end
	end

	def i_name(worker_id)
		@my_dir=File.expand_path(File.dirname(__FILE__.sub(/[0-9a-z._]*$/,'')))
		@my_id=worker_id
		@my_name="#{File.basename($0,".rb")}_#{@my_id}"
		@my_type=@my_name.sub(/\.worker.*/,"")
		p @my_dir
	end

	def i_logger(level)
		$err_logger=Logger.new("#{@my_dir}/var/log/#{@my_name}.log")
		$err_logger.info "Launched #{@my_name}"
		$err_logger.level=$log_level
		if level
			case level
			when "debug"
				$err_logger.level=Logger::DEBUG
			when "info"
				$err_logger.level=Logger::INFO
			when "warn"
				$err_logger.level=Logger::WARN
			when "error"
				$err_logger.level=Logger::ERROR
			when "fatal"
				$err_logger.level=Logger::FATAL
			end
		end
	end

	def i_conf
		require "#{@my_dir}/etc/common.conf.rb"
		my_conf_path="#{@my_dir}/etc/#{@my_name}.conf.rb"
		if File.exists?(my_conf_path)
			require my_conf_path
		end
	end

	def i_chuser
		if $default_user and RUBY_PLATFORM.include?('linux')
			begin
				proc_user=Etc.getpwnam($default_user)
				Process::Sys.setuid(proc_user.uid)
			rescue => e
				raise "Error while changing user to #{$default_user}, #{e.to_s}"
			end
		end
	end

	def i_p2p_db
		require 'mysql2'
		begin
			@p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
		rescue => e_main
			$err_logger.error e_main.to_s
			raise "Error while connecting to MySQL"
		end
		cnt_init()
	end

	def i_validator
		require "#{@my_dir}/#{$validate_lib}"
		@validator=Webrtc_validator.new
	end

	def i_whois_client
		begin
			require $whois_lib
			@fast_whois=Fast_whois.new
		rescue => e_main
			$err_logger.error e_main.to_s
			raise "Error while loading whois client"
		end
	end

	def i_geocity_client
		require 'geoip'
		begin
			@geocity_client=GeoIP.new('var/geoip/GeoLiteCity.dat')
		rescue => e_main
			$err_logger.error e_main.to_s
			raise "Error while starting GeoIP client"
		end
	end

	def i_bunny(queues)
		require 'bunny'
		begin
			@rabbit_client = Bunny.new(:hostname => $rabbit_host, :port => $rabbit_port)
			@rabbit_client.start
			@rabbit_channel = @rabbit_client.create_channel()
			queues.each do |bunny_queue|
				@bunny_workers[bunny_queue] = @rabbit_channel.queue(bunny_queue, :durable => true, :auto_delete => false)
				$err_logger.debug "Adding #{bunny_queue} queue to rabbit workers"
			end
			$err_logger.debug "Rabbit workers: #{@bunny_workers.inspect}"
		rescue => e_main
			$err_logger.error e_main.to_s
			raise "Error while setting RabbitMQ workers"
		end
	end

	def cnt_up(type)
		begin
			req="update #{$p2p_db_counters_table} set count = count + 1 where worker=\"#{@my_type}\" and type=\"#{type}\";"
			$err_logger.debug req
			res=@p2p_db_client.query(req)
			return true
		rescue  => e
			$err_logger.error "Error in SQL counters update for #{@my_type} type #{type}"
			$err_logger.error req
			$err_logger.error e.to_s
			return false
		end
	end

	def cnt_init()
		["failed","success"].each do |field|
			begin
				req="insert ignore into #{$p2p_db_counters_table} values (\"#{@my_type}\",\"#{field}\",0);"
				$err_logger.debug req
				res=@p2p_db_client.query(req)
			rescue => e
				$err_logger.error "Error in SQL init counters #{@my_type} type #{field}"
				$err_logger.error req
				$err_logger.error e.to_s
			end
		end
	end

end
