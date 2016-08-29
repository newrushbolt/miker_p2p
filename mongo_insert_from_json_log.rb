require "#{Dir.pwd}/config.rb"
require 'rubygems'
require 'json'
require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
webrtc_log=mongo_client[:log]

raw_log_json=IO.read($raw_log_txt)
raw_log_data=JSON.parse(raw_log_json)["Logs"]

cnt=0
raw_log_data.each_index do |unit_key|
	raw_me=raw_log_data[unit_key]["me"]
	raw_log_data[unit_key]["webrtc_id"]=raw_me["id"]
	raw_log_data[unit_key]["gg_id"]=""
	raw_log_data[unit_key]["perfomance"]=raw_me["perfomance"]
	raw_log_data[unit_key].delete("me")
	if raw_log_data[unit_key]["goodPeers"].any?
		raw_log_data[unit_key]["goodPeers"].keys.each do |g_key|
			raw_log_data[unit_key]["goodPeers"][g_key].delete("stun")
		end
	else
		raw_log_data[unit_key].delete("goodPeers")
	end
	if ! raw_log_data[unit_key]["badPeers"].any?
		raw_log_data[unit_key].delete("badPeers")
	end
	begin
		webrtc_log.insert_one(raw_log_data[unit_key])
		cnt+=1
	rescue => e
		puts "Error while inserting in Mongo #{raw_log_data[unit_key]["webrtc_id"]}"
		puts e.to_s
	end
end
puts "Finished, inserted #{cnt} lines"
