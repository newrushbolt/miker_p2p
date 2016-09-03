require "#{Dir.pwd}/make_peer_list.lib.rb"
require 'sinatra'

configure do
	set :port, '3302'
	set :bind, '127.0.0.1'
end

get '/peer_list' do
  # matches "GET /peer_list?webrtc_id=11&channel_id=22&neighbors=33"
  response=make_peer_list([params['webrtc_id'],params['channel_id'],params['neighbors']])
end