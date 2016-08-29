require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'sqlite3'
require 'json'
require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
webrtc_raw_peers=mongo_client[:raw_peers]

raw_log_txt=ARGV[0]

raw_log_json=IO.read(raw_log_txt)
raw_log_data=JSON.parse(raw_log_json)["Logs"]
cnt=0
raw_log_data.each_index do |unit_key|
	raw_me=raw_log_data[unit_key]["me"]
	raw_log_data[unit_key]["webrtc_id"]=raw_me["id"]
	raw_log_data[unit_key]["gg_id"]=""
	raw_log_data[unit_key]["unchecked"]=1
	raw_log_data[unit_key].delete("goodPeers")
	raw_log_data[unit_key].delete("badPeers")
	raw_log_data[unit_key].delete("stun")
	raw_log_data[unit_key].delete("me")
	puts raw_log_data[unit_key]
	begin
		webrtc_raw_peers.insert_one(raw_log_data[unit_key])
		cnt+=1
	rescue => e
		puts "Error while inserting in Mongo #{raw_log_data[unit_key]["webrtc_id"]}"
		puts e.to_s
	end
end
puts 'Finished, inserted #{cnt} lines'
