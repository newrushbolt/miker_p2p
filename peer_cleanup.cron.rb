require "#{Dir.pwd}/config.rb"
require 'logger'
require 'rubygems'
require 'mysql2'
require 'json'
require 'mongo'

$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
$out_logger=Logger.new("#{$log_dir}/peer_cleanup.cron.out.log")

Mongo::Logger.logger.level = Logger::WARN
mongo_client = client = Mongo::Client.new($mongo_url)
webrtc_raw_peers=mongo_client[:raw_peers]

def remove_peer_from_sql(webrtc_id)
    begin
		req="delete from #{$p2p_db_state_table} where webrtc_id = \"#{webrtc_id}\";"
		res=$p2p_db_client.query(req)
    rescue  => e
		$out_logger.error "Error while removing peer #{webrtc_id} from SQL"
		$out_logger.error e.to_s
	end
end

begin
	req="select webrtc_id from #{$p2p_db_state_table};"
	puts req
	res=$p2p_db_client.query(req)
rescue  => e
	$out_logger.error "Error while getting all peers"
	$out_logger.error e.to_s
end

all_peers=res
if ! all_peers.any?
	$out_logger.error 'No peers found in DB'
	exit
end

all_peers.each do |peer|
	webrtc_id=peer["webrtc_id"]
#	puts "Found in SQL #{webrtc_id}"
	found_peer=webrtc_raw_peers.find({webrtc_id: "#{webrtc_id}"},{webrtc_id: 1}).to_enum
	if found_peer.any?
	    if found_peer.first["offline"] == true
			$out_logger.info "Removing #{webrtc_id} from SQL cause set offline in Mongo"
			remove_peer_from_sql(webrtc_id)
		end
	else
		$out_logger.info "Removing #{webrtc_id} from SQL cause not found in Mongo"
		remove_peer_from_sql(webrtc_id)
	end
end
