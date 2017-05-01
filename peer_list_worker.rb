$my_dir=File.expand_path(File.dirname(__FILE__))
$my_id=ARGV[0] ? ARGV[0] : 1
$my_name="#{File.basename(__FILE__,".rb")}_#{$my_id}"
$my_type="peer_list_worker"

require 'etc'
require 'mysql2'
require 'bunny'
require 'rubygems'
require 'logger'
require 'json'

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
	require $whois_lib
	$fast_whois=Fast_whois.new
	require "#{$my_dir}/#{$validate_lib}"
	require "#{$my_dir}/lib/make_peer_list.lib.rb"
	require "#{$my_dir}/#{$counters_lib}"
	$validator=Webrtc_validator.new
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while loading libs"
end

begin
	$rabbit_client = Bunny.new(:hostname => $rabbit_host, :port => $rabbit_port)
	$rabbit_client.start
	$rabbit_channel = $rabbit_client.create_channel()
	$rabbit_peer_lists_tasks  = $rabbit_channel.queue("peer_lists_tasks", :durable => true, :auto_delete => false)
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

cnt_init($my_type)

def add_peer_list_to_db(list_json)
	list_raw=JSON.parse(list_json)
	begin
		list_encoded=$p2p_db_client.escape(list_json)
		db_req="insert into #{$p2p_db_peer_lists_table} (conn_id,ts,peer_list) values (\"#{list_raw["conn_id"]}\",\"#{Time.now.to_i}\",\"#{list_encoded}\") ON DUPLICATE KEY UPDATE ts=VALUES(ts),peer_list=VALUES(peer_list);"
		$err_logger.debug "DB req:#{db_req}"
		db_res=$p2p_db_client.query(db_req)
		$err_logger.debug "DB resp:#{db_res}"
		cnt_up($my_type,"success")
	rescue => e_main
		$err_logger.error "Cannot add peer list to DB"
		$err_logger.error e_main.to_s
		cnt_up($my_type,"failed")
	end	
end

while true
	$rabbit_peer_lists_tasks.subscribe(:block => true,:manual_ack => true) do |delivery_info, properties, body|
		$err_logger.debug "Got task for peer #{body}"
		resp=make_peer_list(body.to_s)
		$err_logger.debug "Got peer_list: #{resp}"
		if resp!=nil
			add_peer_list_to_db(resp)
		end
		$rabbit_channel.acknowledge(delivery_info.delivery_tag, false)
		end
end
