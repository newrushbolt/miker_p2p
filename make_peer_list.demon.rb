require "#{Dir.pwd}/config.rb"
require "#{Dir.pwd}/make_peer_list.lib.rb"

require 'sinatra'
require 'etc'
require 'mysql2'

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

$my_name='make_peer_list.demon'

$err_logger=Logger.new("#{$app_dir}/#{$log_dir}/#{$my_name}.log")
$err_logger.info "Launched #{$my_name}"
$err_logger.level=$log_level
if ARGV[1]
    case ARGV[1]
    when debug
	$err_logger.level=Logger::DEBUG
    when info
	$err_logger.level=Logger::IFNO
    when warn
	$err_logger.level=Logger::WARN
    when error
	$err_logger.level=Logger::ERROR
    when fatal
	$err_logger.level=Logger::FATAL
    end
end

$port='3302'
if ARGV.count > 0 and ARGV[0].to_i > 0
	$port=ARGV[0]
end

configure do
	set :port, $port
	set :bind, '127.0.0.1'
	set :lock, true
	set :environment, :production
end

get '/peer_list' do
  resp=make_peer_list([params['webrtc_id'],params['channel_id'],params['neighbors']])
  $err_logger.info request.url
  $err_logger.info resp
  resp
end
