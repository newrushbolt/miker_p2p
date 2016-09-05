require "#{Dir.pwd}/make_peer_list.lib.rb"
require 'sinatra'

$my_name='make_peer_list.demon.rb'
$out_logger=Logger.new("#{$log_dir}/#{$my_name}.out.log")
$out_logger.info "Launched #{__FILE__}"

$port='3302'
if ARGV.count > 0 and ARGV[0].to_i > 0
	$port=ARGV[0]
end

configure do
	set :port, $port
	set :bind, '127.0.0.1'
end

get '/peer_list' do
  resp=make_peer_list([params['webrtc_id'],params['channel_id'],params['neighbors']])
  $out_logger.info request.url
  $out_logger.info resp
  resp
end
