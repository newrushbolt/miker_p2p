require 'sinatra'
require 'rubygems'

$new_arr=["1","2"]

configure do
	set :port, '3301'
	set :bind, '127.0.0.1'
end

get '/arr' do
  $new_arr.to_s
end
