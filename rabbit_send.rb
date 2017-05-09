require 'etc'
require 'mysql2'
require 'bunny'
require 'logger'
require 'json'
require "#{Dir.pwd}/etc/common.conf.rb"

rabbit_client = Bunny.new(:hostname => "localhost")
rabbit_client.start

rabbit_channel = rabbit_client.create_channel()
rabbit_q = rabbit_channel.queue("common_online_peers", :durable => true, :auto_delete => false)
#rabbit_peer_log = rabbit_channel.queue("peer_log", :durable => true, :auto_delete => false)
#data={:bad_peer => {:Conn_id => "gikhk7w16hbz28yr7yo7ztlj"},:channel_id => "7:user75781_990_240_1.11",:conn_id => "vmen5dteud7maklbwforf0ei",:gg_id => "f0cbe600-f0e2-823c-ba9c-f8617c362de3", :good_peer => {:Conn_id => "gikhk7w16hbz28yr7yo7z4lj", :P2p => 250, :Ltime => 0},:ip => "195.170.179.217",:timestamp => 1494016208}
#rabbit_peer_log.publish(JSON.generate(data), :routing_key => rabbit_peer_log.name)

# rabbit_channel = rabbit_client.create_channel
# rabbit_slow_online = rabbit_channel.queue("peer_log", :durable => true, :auto_delete => false)
# rabbit_slow_online.delete
# exit

# # rabbit_slow_online.delete
# # exit
# prng=Random.new

 for i in (1..ARGV[0].to_i)
	 #data= {:timestamp => Time.now.to_i,:gg_id => ('a'..'z').to_a.shuffle[0,8].join,:conn_id => ('a'..'z').to_a.shuffle[0,8].join.to_s,:ip => "#{prng.rand(60..130)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}",:channel_id => "614fghd7"}
	data={:conn_id => "r2nm7umrub0vtjtxtekrthcn",:gg_id => "86039faa-ffdb-259c-06ca-6262f46a92eb",:channel_id => "7:user75781_860_720_1.11",:ip => "93.171.19.157",:timestamp => 1494355644}
	puts data
	rabbit_q.publish(JSON.generate(data), :routing_key => rabbit_q.name)
end
