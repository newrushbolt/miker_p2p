
require 'mongo'
require "#{Dir.pwd}/config.rb"

$mongo_client = nil
$webrtc_raw_peers= nil
$webrtc_raw_peers_cursor= nil


Mongo::Logger.logger.level = Logger::INFO
$mongo_client = Mongo::Client.new($mongo_url, :min_pool_size => 1 , :max_pool_size => 1)
$webrtc_raw_peers=$mongo_client[:raw_peers]

(250..280).each do |i|
    (1..250).each do |ii|
	res=$webrtc_raw_peers.insert_one({:channel_id => "456239094_test_load", :gg_id => "48515182_test_load", :ip => "91.#{i}.#{ii}.1", :timestamp => 1473500520194, :unchecked => 1, :webrtc_id => "c48134ea-test-#{i}-#{ii}"})
	
	puts res.to_a
#	exit
    end
end
