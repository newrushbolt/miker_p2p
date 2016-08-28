db.createCollection("log")
db.createCollection("raw_peers",{ capped : true, size : 5242880})
db.raw_peers.createIndex({webrtc_id:1})
db.raw_peers.createIndex({unchecked:1})