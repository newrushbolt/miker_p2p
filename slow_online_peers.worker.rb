$my_dir=File.expand_path(File.dirname(__FILE__))
$my_name=File.basename(__FILE__,".rb")

require 'etc'
require 'mysql2'
require 'bunny'
require 'rubygems'
require 'logger'
require 'json'

require "#{$my_dir}/etc/common.conf.rb"
if File.exists?("#{$my_dir}/etc/#{my_name}.conf.rb")
	require "#{$my_dir}/etc/#{my_name}.conf.rb"
end

require $whois_lib

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
if ARGV[0]
    case ARGV[0]
    when debug
	$err_logger.level=Logger::DEBUG
    when info
	$err_logger.level=Logger::INFO
    when warn
	$err_logger.level=Logger::WARN
    when error
	$err_logger.level=Logger::ERROR
    when fatal
	$err_logger.level=Logger::FATAL
    end
end

rabbit_client = Bunny.new(:hostname => "localhost")
rabbit_client.start

rabbit_channel = rabbit_client.create_channel
rabbit_slow_online = rabbit_channel.queue("slow_online_peers")
while true
	rabbit_slow_online.subscribe(:block => true) do |delivery_info, properties, body|
		puts "Received #{body}"
		sleep 5
		delivery_info.consumer.cancel
	end
end
