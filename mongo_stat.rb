require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'json'
require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
webrtc_raw_peers=mongo_client[:raw_peers]

puts webrtc_raw_peers.find({unchecked: 1}).count();
puts webrtc_raw_peers.find({unchecked: 0}).count();
puts webrtc_raw_peers.find({offline: true}).count();
