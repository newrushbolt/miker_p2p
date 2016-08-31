require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'json'
require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
webrtc_raw_peers=mongo_client[:raw_peers]

puts 'Unchecked: 1'
puts webrtc_raw_peers.find({unchecked: 1}).count()
puts 'Unchecked: 0'
puts webrtc_raw_peers.find({unchecked: 0}).count()
puts 'Distinct webrtc_id'
puts webrtc_raw_peers.find.distinct(:webrtc_id).count()
puts 'Offline'
puts webrtc_raw_peers.find({offline: true}).count();
puts 'Total'
puts webrtc_raw_peers.find().count()
