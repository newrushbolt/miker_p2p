require "#{Dir.pwd}/config.rb"
require 'etc'
require 'mysql2'
require 'bunny'

rabbit_client = Bunny.new(:hostname => "localhost")
rabbit_client.start

rabbit_channel = rabbit_client.create_channel
rabbit_slow_online = rabbit_channel.queue("slow_online_peers")
for i in (1..20)
	rabbit_slow_online.publish("Hello#{i}", :routing_key => rabbit_slow_online.name)
end