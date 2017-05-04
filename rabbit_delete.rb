require 'etc'
require 'mysql2'
require 'bunny'
require 'logger'
require 'json'
require "#{Dir.pwd}/etc/common.conf.rb"


rabbit_channels=['common_online_peers','slow_online_peers','peer_log','peer_lists_tasks','slow_online _peers','offline_peers']
rabbit_client = Bunny.new(:hostname => "localhost")
rabbit_client.start
rabbit_channel = rabbit_client.create_channel

rabbit_channels.each do |channel|
    begin
	rabbit_q=rabbit_channel.queue(channel, :durable => true, :auto_delete => false)
	rabbit_q.delete
    rescue => e_main
	puts e_main.to_s
    end
end
