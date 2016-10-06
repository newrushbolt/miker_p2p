$my_dir=File.expand_path(File.dirname(__FILE__))
$my_id=ARGV[0] ? ARGV[0] : 1
$my_name="#{File.basename(__FILE__,".rb")}_#{$my_id}"

require 'sinatra'
require 'etc'
require 'json'
require 'mysql2'
require 'logger'

require "#{Dir.pwd}/etc/common.conf.rb"
if File.exists?("#{$my_dir}/etc/#{$my_name}.conf.rb")
	require "#{$my_dir}/etc/#{$my_name}.conf.rb"
end
require "#{Dir.pwd}/lib/make_peer_list.lib.rb"


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

$port=$make_peer_list_start_port + $my_id.to_i

configure do
	set :port, $port
	set :bind, '127.0.0.1'
	set :lock, true
	set :environment, :production
	set :logging, false
	set :dump_errors, true
end

get '/peer_list' do
  resp=make_peer_list([params['webrtc_id'],params['channel_id'],params['neighbors']])
  $err_logger.info request.url
  $err_logger.info resp
  return resp
end
