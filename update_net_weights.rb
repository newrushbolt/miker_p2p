require 'rubygems'
require 'sqlite3'
require 'json'

peer_db_file='peers.sqlite3'
peer_neighbors_table='peer_neighbors_raw'
peer_state_table='peer_state'
peer_db=SQLite3::Database.new(peer_db_file)

cnt=0
raw_log_data.each do |peer|
	cnt+=1
	# req="select * from #{peer_state_table} where webrtc_id = \"#{peer["me"]["id"]}\""
	# res=peer_db.execute(req)
	# if res.any?
		 peer["goodPeers"].each do |good_peer_id,good_peer_data|
			puts good_peer_id
			# puts "Data"
			# puts good_peer_data["bytes"]
			# puts good_peer_data["ping"]
			# puts good_peer_data["chunk_rate"]
			req="insert into #{peer_neighbors_table} values (\"#{peer["me"]["id"]}\",\"#{good_peer_id}\",#{good_peer_data["ping"]},#{good_peer_data["chunk_rate"]},#{good_peer_data["bytes"]},#{peer["timestamp"]},NULL,NULL);"
			begin
				res=peer_db.execute(req)
		    rescue  => e
				puts "Error in DB insert for #{peer["id"]} and goodPeer #{good_peer_id}"
				puts e.to_s
				puts req
				puts peer
			end
		end
		end
		peer["badPeers"].each do |bad_peer_id,bad_peer_data|
			puts bad_peer_id
			puts "Data"
			puts bad_peer_data
			# req="select * from #{peer_state_table} where wertc_id = \"#{peer["me"]["id"]}\""
		# res=peer_db.execute(req)
		end
	# else
		# puts "Peer #{peer["me"]["id"]} with ip #{peer["ip"]} doesn't exist yet, skipping"
	# end
end
