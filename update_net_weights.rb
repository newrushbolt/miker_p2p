require 'rubygems'
require 'sqlite3'
require 'json'

peer_db_file='peers.sqlite3'
peer_neighbors_table='peer_neighbors_raw'
peer_state_table='peer_state'
net_weights_table='peer_state'
peer_db=SQLite3::Database.new(peer_db_file)

cnt=0
begin
	#Getting all id in the system
	req="select webrtc_id, from #{peer_state_table} order by last_online desc;"
	# puts req
	res=peer_db.execute(req)
	# puts res.to_s
	peer_list=res
rescue => e
    puts "Error while getting peer list"
	puts e.to_s
end
peer_list.each do |peer_id|
	#get peer info
	#puts peer_id
	begin
		req="select webrtc_id, from #{peer_state_table} where webrtc_id = \"#{peer_id[0]}\";"
		#puts req
		res=peer_db.execute(req)
	rescue => e
		puts "Error while getting peer #{peer_id}"
		puts e.to_s
	end
	peer_info[]=res
	raise 'fuck'
end