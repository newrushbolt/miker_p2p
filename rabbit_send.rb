require 'etc'
require 'mysql2'
require 'bunny'
require 'logger'
require 'json'
require "#{Dir.pwd}/etc/common.conf.rb"

rabbit_client = Bunny.new(:hostname => "localhost")
rabbit_client.start

rabbit_channel = rabbit_client.create_channel
rabbit_slow_online = rabbit_channel.queue("common_online_peers", :durable => true, :auto_delete => true)
# rabbit_slow_online.delete
# exit
prng=Random.new

for i in (1..ARGV[0].to_i)
	#data= {:timestamp => Time.now.to_i,:gg_id => ('a'..'z').to_a.shuffle[0,8].join,:webrtc_id => ('a'..'z').to_a.shuffle[0,8].join.to_s,:ip => "#{prng.rand(60..130)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}",:channel_id => "614fghd7"}
		data= {:timestamp => Time.now.to_i,:gg_id => ('a'..'z').to_a.shuffle[0,8].join,:webrtc_id => ('a'..'z').to_a.shuffle[0,8].join.to_s,:ip => "#{prng.rand(90..97)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}.1",:channel_id => "614fghd7"}
	puts data
	rabbit_slow_online.publish(JSON.generate(data), :routing_key => rabbit_slow_online.name)
end
