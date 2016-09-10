
require 'etc'
require 'geoip'
require 'json'
require 'logger'
require 'mongo'
require 'mysql2'
require 'rest-client'
require 'rubygems'
require 'ruby-prof'
require 'whois'
require "#{Dir.pwd}/config.rb"

$mongo_client = nil
$webrtc_raw_peers= nil
$webrtc_raw_peers_cursor= nil


Mongo::Logger.logger.level = Logger::WARN
$mongo_client = Mongo::Client.new($mongo_url, :min_pool_size => 10 , :max_pool_size => 50)
$webrtc_raw_peers=$mongo_client[:raw_peers]
(91..101).each do |i|
    (1..254).each do |ii|
	$webrtc_raw_peers.insert_one({:channel_id => "456239094_test_load", :gg_id => "48515182_test_load", :ip => "#{i}.#{ii}.0.1", :timestamp => 1473500520194, :unchecked => 1, :webrtc_id => "c48133ea-test-#{i}-#{ii}"})
    end
end
