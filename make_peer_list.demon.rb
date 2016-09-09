require "#{Dir.pwd}/config.rb"
require "#{Dir.pwd}/make_peer_list.lib.rb"
require 'rubygems'
require 'mysql2'
require 'logger'
require 'json'
require 'sinatra'
require 'etc'

if $default_user and RUBY_PLATFORM.include?('linux')
    begin
        proc_user=Etc.getpwnam($default_user)
        Process::Sys.setuid(proc_user.uid)
    rescue => e
        puts "Error while changing user to #{$default_user}"
        puts e.to_s
    end
end

$my_name='make_peer_list.demon.rb'

$out_logger=Logger.new("#{$log_dir}/#{$my_name}.out.log")
$out_logger.info "Launched #{__FILE__}"
$err_logger=Logger.new("#{$log_dir}/#{$my_name}.out.log")
$out_logger.level=Logger::ERROR
$err_logger.level=Logger::ERROR
if ARGV[1]
    case ARGV[1]
    when debug
	$out_logger.level=Logger::DEBUG
	$err_logger.level=Logger::DEBUG
    when info
	$out_logger.level=Logger::INFO
	$err_logger.level=Logger::IFNO
    when warn
	$out_logger.level=Logger::WARN
	$err_logger.level=Logger::WARN
    when error
	$out_logger.level=Logger::ERROR
	$err_logger.level=Logger::ERROR
    when fatal
	$out_logger.level=Logger::FATAL
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
  $out_logger.info request.url
  $out_logger.info resp
  resp
end
