#!/bin/bash

psql p2p -h 127.0.0.1 -p 5432 -Up2p -W -c "with channel_data as (
	select conn_id,channel_id from peers where channel_id = (
		select channel_id from (
			select count(conn_id),channel_id from peers group by channel_id order by count(conn_id) desc limit 1
			) as top_channel
		) limit 1
	)
select genereate_peer_list(conn_id,channel_id,'20') from channel_data;"
