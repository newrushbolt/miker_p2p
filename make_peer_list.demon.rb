require "#{Dir.pwd}/config.rb"
require "#{Dir.pwd}/make_peer_list.lib.rb"
require 'rubygems'
require 'mysql2'
#require 'mongo'
require 'logger'
require 'json'
require 'sinatra'

$my_name='make_peer_list.demon.rb'

$out_logger=Logger.new("#{$log_dir}/#{$my_name}.out.log")
$out_logger.info "Launched #{__FILE__}"
$err_logger=Logger.new("#{$log_dir}/#{$my_name}.out.log")

if ARGV[1]
    case ARGV[1]
    when debug
	$out_logger.level=Loger::DEBUG
	$err_logger.level=Loger::DEBUG
    when info
	$out_logger.level=Loger::INFO
	$err_logger.level=Loger::IFNO
    when warn
	$out_logger.level=Loger::WARN
	$err_logger.level=Loger::WARN
    when error
	$out_logger.level=Loger::ERROR
	$err_logger.level=Loger::ERROR
    when fatal
	$out_logger.level=Loger::FATAL
	$err_logger.level=Loger::FATAL
    end
    $out_logger.level=Loger::ERROR
    $err_logger.level=Loger::ERROR
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
