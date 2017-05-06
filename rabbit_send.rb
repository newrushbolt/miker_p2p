require 'etc'
require 'mysql2'
require 'bunny'
require 'logger'
require 'json'
require "#{Dir.pwd}/etc/common.conf.rb"

rabbit_client = Bunny.new(:hostname => "localhost")
rabbit_client.start

rabbit_channel = rabbit_client.create_channel()
rabbit_peer_log = rabbit_channel.queue("peer_log", :durable => true, :auto_delete => false)
data={:bad_peer => {:Conn_id => "gikhk7w16hbz28yr7yo7ztlj"},:channel_id => "7:user75781_990_240_1.11",:conn_id => "vmen5dteud7maklbwforf0ei",:gg_id => "f0cbe600-f0e2-823c-ba9c-f8617c362de3", :good_peer => {:Conn_id => "gikhk7w16hbz28yr7yo7z4lj", :P2p => 250, :Ltime => 0},:ip => "195.170.179.217",:timestamp => 1494016208}
rabbit_peer_log.publish(JSON.generate(data), :routing_key => rabbit_peer_log.name)

# rabbit_channel = rabbit_client.create_channel
# rabbit_slow_online = rabbit_channel.queue("peer_log", :durable => true, :auto_delete => false)
# rabbit_slow_online.delete
# exit

# # rabbit_slow_online.delete
# # exit
# prng=Random.new

# for i in (1..ARGV[0].to_i)
	# #data= {:timestamp => Time.now.to_i,:gg_id => ('a'..'z').to_a.shuffle[0,8].join,:conn_id => ('a'..'z').to_a.shuffle[0,8].join.to_s,:ip => "#{prng.rand(60..130)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}",:channel_id => "614fghd7"}
		# data= {:timestamp => Time.now.to_i,:gg_id => "9d361725-70db-fd76-0bd1-efad7668f032",:conn_id => "1:#{('a'..'z').to_a.shuffle[0,9].join.to_s}",:ip => "#{prng.rand(90..97)}.#{prng.rand(1..252)}.#{prng.rand(1..252)}.1",:channel_id => "614fghd7", :unchecked => true}
	# puts data
	# rabbit_slow_online.publish(JSON.generate(data), :routing_key => rabbit_slow_online.name)
# end
