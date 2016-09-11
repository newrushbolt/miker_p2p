$my_dir=File.expand_path(File.dirname(__FILE__))

require "#{$my_dir}/config.rb"
require 'rubygems'
require 'json'
require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
mongo_client = Mongo::Client.new($mongo_url)
webrtc_raw_peers=mongo_client[:raw_peers]

puts "Conn_current: #{mongo_client.database.command( { serverStatus: 1 } ).first["connections"]["current"]}"
puts "Doc_inserted: #{mongo_client.database.command( { serverStatus: 1 } ).first["metrics"]["document"]["inserted"]}"
puts "Doc_returned: #{mongo_client.database.command( { serverStatus: 1 } ).first["metrics"]["document"]["returned"]}"
puts "Unchecked: #{webrtc_raw_peers.find({unchecked: 1}).count()}"
puts "Checked: #{webrtc_raw_peers.find({unchecked: 0}).count()}"
puts "Offline: #{webrtc_raw_peers.find({offline: true}).count();}"
puts "Total: #{webrtc_raw_peers.find().count()}"
