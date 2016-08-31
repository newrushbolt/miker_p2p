require "#{Dir.pwd}/config.rb"
require 'logger'
require 'rubygems'
require 'sqlite3'
require 'json'
require 'mongo'

$peer_db=SQLite3::Database.new($peer_db_file)
$out_logger=Logger.new("#{$log_dir}/out.log")
$err_logger=Logger.new("#{$log_dir}/err.log")

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
webrtc_raw_peers=mongo_client[:raw_peers]

begin
	req="select webrtc_id from #{$peer_state_table};"
	res=$peer_db.execute(req)
rescue  => e
	STDERR.puts "Error while getting all peers"
	STDERR.puts e.to_s
end

all_peers=res
if ! all_peers.any?
	STDERR.puts 'No peers found in DB'
	exit
end

all_peers.each do |peer|
	webrtc_id=peer[0]
#	puts "Found in SQL #{webrtc_id}"
	found_peer=webrtc_raw_peers.find({webrtc_id: "#{webrtc_id}"},{webrtc_id: 1})
	if found_peer.any?
#	    found_peer.each do |f_peer|
#		puts "Found in Mongo #{f_peer["webrtc_id"]}"
#	    end
	else
	    puts "Removing #{webrtc_id} from SQL couse not found in Mongo"
	    begin
		req="delete from #{$peer_state_table} where webrtc_id = \"#{webrtc_id}\";"
		res=$peer_db.execute(req)
	    rescue  => e
		STDERR.puts "Error while removing peer #{webrtc_id} from SQL"
		STDERR.puts e.to_s
	    end
	end
end