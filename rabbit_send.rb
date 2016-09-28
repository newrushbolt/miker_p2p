
require 'etc'
require 'mysql2'
require 'bunny'
require 'logger'
require 'json'
require "#{Dir.pwd}/etc/common.conf.rb"

rabbit_client = Bunny.new(:hostname => "localhost")
rabbit_client.start

rabbit_channel = rabbit_client.create_channel
rabbit_slow_online = rabbit_channel.queue("slow_online_peers", :durable => true)
for i in (1..10)
	data= {:timestamp => 0,:gg_id => "some_gg_id",:webrtc_id => "somewebrtcid",:ip => "8.8.8.#{i}",:channel_id => "614fghd7",:unchecked => 1}
	rabbit_slow_online.publish(JSON.generate(data), :routing_key => rabbit_slow_online.name)
end