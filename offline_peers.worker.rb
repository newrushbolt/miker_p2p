$my_dir=File.expand_path(File.dirname(__FILE__))
$my_id=ARGV[0] ? ARGV[0] : 1
$my_name="#{File.basename(__FILE__,".rb")}_#{$my_id}"
$my_type=$my_name.sub(/\.worker.*/,"")

require 'etc'
require 'mysql2'
require 'bunny'
require 'rubygems'
require 'logger'
require 'json'
require 'ipaddr'

require "#{$my_dir}/etc/common.conf.rb"
if File.exists?("#{$my_dir}/etc/#{$my_name}.conf.rb")
	require "#{$my_dir}/etc/#{$my_name}.conf.rb"
end

if $default_user and RUBY_PLATFORM.include?('linux')
    begin
        proc_user=Etc.getpwnam($default_user)
        Process::Sys.setuid(proc_user.uid)
    rescue => e
        raise "Error while changing user to #{$default_user}, #{e.to_s}"
    end
end

$err_logger=Logger.new("#{$my_dir}/var/log/#{$my_name}.log")
$err_logger.info "Launched #{$my_name}"
$err_logger.level=$log_level
if ARGV[1]
    case ARGV[1]
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

begin
	require "#{$my_dir}/#{$validate_lib}"
	require "#{$my_dir}/#{$counters_lib}"
	$validator=Webrtc_validator.new	
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while loading libs"
end

begin
	$rabbit_client = Bunny.new(:hostname => "localhost")
	$rabbit_client.start
	$rabbit_channel = $rabbit_client.create_channel()
	$rabbit_offline = $rabbit_channel.queue("offline_peers", :durable => true, :auto_delete => false)
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while connecting to RabbitMQ"
end

begin
	$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while connecting to MySQL"
end

def remove_peer(peer)
	begin
		req="delete from #{$p2p_db_state_table} where conn_id = \"#{peer["conn_id"]}\";"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
	rescue  => e
		$err_logger.error "Error in SQL removal for #{peer["conn_id"]}"
		$err_logger.error e.to_s
		$err_logger.error req
		return false
	end
	aff=$p2p_db_client.affected_rows
	$err_logger.debug "#{aff} rows affected"
	case aff
	when 1
		return true
	when 0
		return false
	else
		$err_logger.error "Removed more than 1 (#{afk}) records for conn_id:#{peer["conn_id"]}"
		return false
	end
end

cnt_init($my_type)

while true
	$rabbit_offline.subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
		$err_logger.debug "Got info:\n #{body}"
		peer=JSON.parse(body)
		fields=["conn_id"]
		if $validator.v_log_fields(peer,fields) and $validator.v_conn_id(peer["conn_id"])
			if remove_peer(peer)==true
				$err_logger.info "Peer #{peer["conn_id"]} removed successfull"
				cnt_up($my_type,"success")
			else
				$err_logger.warn "Peer #{peer["conn_id"]} removal failed"
				cnt_up($my_type,"failed")
			end
		else
			$err_logger.error "Got incorrect peer:\n#{peer}"
			$err_logger.error "conn_id: #{$validator.v_conn_id(peer["conn_id"]).inspect}"
			cnt_up($my_type,"invalid")
		end
		$rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
	end
end
