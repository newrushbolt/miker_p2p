#Generating each peer distances

require 'rubygems'
require 'sqlite3'
require 'json'

peer_db_file='peers.sqlite3'
peer_neighbors_table='peer_neighbors'
peer_db=SQLite3::Database.new(peer_db_file)
raw_log_txt='c:\Users\Serge\Downloads\candy2.txt\candy.small.txt'
#raw_log_txt='c:\Users\Serge\Downloads\candy2.txt\candy2.txt'
raw_log_json=IO.read(raw_log_txt)

raw_log_data=JSON.parse(raw_log_json)["Logs"]
cnt=0
raw_log_data.each do |peer|
	cnt+=1
#	req="select * from #{peer_state_table} where webrtc_id = \"#{peer["me"]["id"]}\""
#	res=peer_db.execute(req)
#	puts ! res.any? ? "Nothing found" : res
#	if res.any?
		 peer["goodPeers"].each do |good_peer_id,good_peer_data|
			puts good_peer_id
			puts "Data"
			puts good_peer_data["bytes"]
			puts good_peer_data["ping"]
			puts good_peer_data["chunk_rate"]
			req="insert into #{peer_neighbors_tables} values (\"#{peer["me"]["id"]}\",\"#{good_peer_id}\",#{good_peer_data}[""])"
		# # res=peer_db.execute(req)
		end
		peer["badPeers"].each do |bad_peer_id,bad_peer_data|
			puts bad_peer_id
			puts "Data"
			puts bad_peer_data
			# req="select * from #{peer_state_table} where wertc_id = \"#{peer["me"]["id"]}\""
		# res=peer_db.execute(req)
		end

#	end
end
