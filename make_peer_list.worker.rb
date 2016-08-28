require 'rubygems'
require 'sqlite3'
require 'json'

$peer_id=ARGV[0]
$peers_required=ARGV[1]

$peer_db_file='peers.sqlite3'
$peer_state_table='peer_state'
$peer_db=SQLite3::Database.new($peer_db_file)

begin
	req="select count(webrtc_id) from #{$peer_state_table};"
	res=$peer_db.execute(req)
rescue  => e
    STDERR.puts "Error while geting peers"
    STDERR.puts e.to_s
end

def get_random_peers(peer_count)
	begin
		req="select webrtc_id from #{$peer_state_table} limit #{peer_count};"
		res=$peer_db.execute(req)
    rescue  => e
        STDERR.puts "Error while geting peers"
        STDERR.puts e.to_s
        return nil
    end
	return res
end

random_peers=get_random_peers($peers_required)

if random_peers and random_peers.any?
	puts JSON.generate(random_peers)
else
	puts JSON.generate({:error => "Cannot get peers"})
end

#test_commit_record


