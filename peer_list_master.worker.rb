$my_dir=File.expand_path(File.dirname(__FILE__))
$my_id=ARGV[0] ? ARGV[0] : 1
$my_name="#{File.basename(__FILE__,".rb")}_#{$my_id}"
$my_type=$my_name.sub(/\.worker.*/,"")

require 'rest-client'
require 'etc'
require 'bunny'
require 'mysql2'
require 'logger'

require "#{Dir.pwd}/etc/common.conf.rb"
if File.exists?("#{$my_dir}/etc/#{$my_name}.conf.rb")
	require "#{$my_dir}/etc/#{$my_name}.conf.rb"
end
require "#{$my_dir}/lib/make_peer_list.lib.rb"


if $default_user and RUBY_PLATFORM.include?('linux')
    begin
        proc_user=Etc.getpwnam($default_user)
        Process::Sys.setuid(proc_user.uid)
    rescue => e
        puts "Error while changing user to #{$default_user}"
        puts e.to_s
		exit
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
	require "#{$my_dir}/#{$counters_lib}"
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

def get_online_peers()
	local_online_peers={}
	db_req="select conn_id,last_update from #{$p2p_db_state_table} order by last_update;"
	$err_logger.debug "DB req:#{db_req}"
	db_res=$p2p_db_client.query(db_req)
	$err_logger.debug "DB resp:#{db_res}"
	db_res.each do |online_peer|
		peer={ :"#{online_peer["conn_id"]}" => online_peer["last_update"] }
		$err_logger.debug "Got online peer info: #{peer}"
		local_online_peers=local_online_peers.merge(peer)
	end
	$err_logger.info "Returning #{local_online_peers.count} online peers"
	$err_logger.debug "Returning peers: #{local_online_peers}"
	return local_online_peers
end

def get_peer_lists()
	local_peer_lists={}
	db_req="select conn_id,ts from #{$p2p_db_peer_lists_table} order by ts;"
	$err_logger.debug "DB req:#{db_req}"
	db_res=$p2p_db_client.query(db_req)
	$err_logger.debug "DB resp:#{db_res}"
	db_res.each do |peer_list|
		list={ :"#{peer_list["conn_id"]}" => peer_list["ts"] }
		$err_logger.debug "Got peer list: #{list}"
		local_peer_lists=local_peer_lists.merge(list)
	end
	$err_logger.info "Returning #{local_peer_lists.count} peer lists"
	$err_logger.debug "Returning peer lists: #{local_peer_lists}"
	return local_peer_lists	
end

def get_absent_peers(local_online_peers,local_peer_lists)
	local_absent_peers=local_online_peers.select{|k,v|! local_peer_lists[k]}
	$err_logger.info "Returning #{local_absent_peers.count} absent peers"
	$err_logger.debug "Returning absent peers: #{local_absent_peers}"
	return local_absent_peers
end

def get_outdated_peers(local_online_peers,local_peer_lists)
	ts=Time.now.to_i
	local_outdated_peers=local_online_peers.select{|k,v|local_peer_lists[k] and (local_peer_lists[k] < (ts - 120))}
	$err_logger.info "Returning #{local_outdated_peers.count} outdated peers"
	$err_logger.debug "Returning outdated peers: #{local_outdated_peers}"
	return local_outdated_peers
end

def add_lists_tasks(tasks)
	$err_logger.info "Got #{tasks.count} tasks to add"
	$err_logger.debug "Got tasks to add: #{tasks}"
	tasks.each do |task|
		begin
			$err_logger.debug "Adding task: #{task}"
			$rabbit_peer_lists_tasks.publish(task.to_s, :routing_key => $rabbit_peer_lists_tasks.name)
			cnt_up($my_type,"success")
		rescue => e_main
			$err_logger.error "Error while adding task to RabbitMQ"
			$err_logger.error e_main.to_s
			cnt_up($my_type,"failed")
		end
	end
end


cnt_init($my_type)

while true
	#берем текущий список онлайн-пиров
	new_online_peers=get_online_peers
	#берем текущий список списков пиров
	new_peer_lists=get_peer_lists
	#проверяем, для всех ли есть списки пиров
	absent_peers=get_absent_peers(new_online_peers,new_peer_lists)
	#генерим для тех, для кого нет
	add_lists_tasks(absent_peers.keys)
	#проверяем, есть ли устаревшие (старше 2 минут по дефолту) списки пиров
	outdated_peers=get_outdated_peers(new_online_peers,new_peer_lists)
	#генерим для тех, для кого устарели
	add_lists_tasks(outdated_peers.keys)
	sleep(30)
end



