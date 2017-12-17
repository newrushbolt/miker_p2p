CREATE OR REPLACE FUNCTION migrate_peers_to_v2_f() RETURNS TRIGGER AS $$
BEGIN
	RAISE NOTICE 'Migrating user %', OLD.conn_id;
	perform insert_new_peer(OLD.conn_id,OLD.channel_id,OLD.ip,OLD.gg_id);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER migrate_peers_to_v2 BEFORE DELETE on peers
FOR EACH ROW EXECUTE PROCEDURE migrate_peers_to_v2_f();

CREATE OR REPLACE FUNCTION create_channel(my_channel_id varchar(45)) RETURNS int AS $$
DECLARE
	channel_cnt smallint;
	partition_cnt smallint;
	my_channel_i_id int;
	partition_name text;
BEGIN
	RAISE NOTICE 'Adding channel %', my_channel_id;
	select count(channel_i_id) from channels_settings into channel_cnt where channel_id = my_channel_id;
	RAISE NOTICE 'We got % of this channel', channel_cnt;
	IF channel_cnt = 1::smallint THEN
		select channel_i_id from channels_settings into my_channel_i_id where channel_id = my_channel_id limit 1;
		RAISE NOTICE 'This channel i_id is %', my_channel_i_id;
	ELSE
		insert into channels_settings values(my_channel_id) RETURNING channel_i_id into my_channel_i_id;
	END IF;

	select ('peers_v2_p_' || my_channel_i_id) as p_name into partition_name;
	RAISE NOTICE 'Part name is %', partition_name;
	select count(table_name) into partition_cnt FROM information_schema.tables WHERE table_name = partition_name;
	RAISE NOTICE 'We got % this partition', partition_cnt;
	IF partition_cnt <> 1 THEN
		RAISE NOTICE 'Creating partition %', partition_name;
		execute 'CREATE TABLE ' || partition_name || ' partition of peers_v2(
			primary key (conn_id,channel_id))
			for values in (' || my_channel_i_id || ')';
		--execute 'ALTER TABLE ' || partition_name || ' OWNER to p2p';
		--execute 'CREATE INDEX ' || partition_name || '_conn_chann_ip ON ' || partition_name || ' (conn_id,channel_id,ip)';
	END IF;
	RETURN my_channel_i_id;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_new_peer(my_conn_id varchar(45),my_channel_id varchar(45), my_ip inet, my_gg_id varchar(45) default NULL) RETURNS void AS $$
DECLARE
	channel_i_id int;
BEGIN
	select create_channel(my_channel_id) into channel_i_id;
	RAISE NOTICE 'Creating channel returned: %', channel_i_id;
	insert into peers_v2 values(my_conn_id,channel_i_id,my_gg_id,my_ip);
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION genereate_peer_list(my_conn_id varchar(45), my_channel_id varchar(45),required_peers_num smallint) RETURNS TABLE(conn_id varchar(45), type smallint) AS $$
BEGIN
	-- Создаем временную таблицу для исключения уже добавленных пиров
	create temp table tmp_exclude_conn_id (
		conn_id varchar(45) UNIQUE NOT NULL,
		type smallint NOT NULL
	);

	-- Создаем временную таблицу для списка пиров
	create temp table tmp_peer_list (
		conn_id varchar(45) UNIQUE NOT NULL,
		type smallint NOT NULL
	);

	-- Добавляем в исключения себя
	insert into tmp_exclude_conn_id values(my_conn_id,0);

	-- Добавляем в исключения перегруженные пиры
	-- insert into tmp_exclude_conn_id (
	-- 	select conn_data.conn_id,type_data.type from (select * from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and (select count(distinct peer_conn_id) from peers_good where peers_good.conn_id=peers.conn_id) > (select slots_per_seed from channels_settings)) as conn_data,
	-- 	(select 1 as type) as type_data
	-- );

	-- 100 - хорошие пиры + город
	-- select conn_id,bytes/ltime alias speed FROM peers_good where peer_conn_id=my_conn_id;

	-- 110 - хорошие пиры + регион

	-- 120 - "хорошие сети" + город
	-- insert into tmp_peer_list (
	-- 	select conn_id from (
	-- 		select conn_id from peers
	-- 			where conn_id NOT IN (select conn_id from tmp_exclude_conn_id)
	-- 			and ip << ANY (
	-- 				select network from networks
	-- 					where network in (
	-- 						select network from networks_good_stats_30 where peer_network << my_conn_id
	-- 					)
	-- 					and city = (
	-- 						select city from networks where network << (select ip from peers where conn_id = my_conn_id)
	-- 					)
	-- 	) alias conn_data
	-- 	full join (select 120 alias type) alias type_data on true where conn_data.conn_id != ''
	-- );

	-- 130 - "хорошие сети" + регион
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and ip << ANY (
	-- 				select networks.network from networks
	-- 					where networks.network in (
	-- 						select networks_good_stats_30.network from networks_good_stats_30 where networks_good_stats_30.peer_network << (
	-- 							select peers.ip from peers where peers.conn_id = my_conn_id)
	-- 					)
	-- 					and city = (
	-- 						select region from networks where network << (select peers.ip from peers where peers.conn_id = my_conn_id)
	-- 					)
	-- 			)
	-- 	) as conn_data,
	-- 	(select 130 as type) as type_data
	-- 	);

	-- -- 200  - Пиры в одной сети, сеть не крупнее /23
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.channel_id = my_channel_id
				and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and ip << ANY (
					select networks.network from networks
	 					where network >> ANY (select peers.ip from peers where peers.conn_id=my_conn_id)
	 					and masklen(network) >= 23
						order by network desc limit 1
				) order by peers.conn_id limit required_peers_num
		) as conn_data,
		(select 200 as type) as type_data
	);

	-- -- -- 210 - Пиры в соседних сетях по AS сети, не крупнее /21
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
	-- 			and peers.ip << ANY (
	-- 				select networks.network from networks
	--  					-- where networks.network >> ANY (select peers.ip from peers where peers.conn_id=my_conn_id)
	-- 					where masklen(networks.network) > 21
	-- 					and asn = (
	-- 						select networks.asn from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 			) limit required_peers_num
	-- 	) as conn_data,
	-- 	(select 210 as type) as type_data
	-- );

	-- -- 220 - сети в пиринге, в максимум в два хопа(НЕ РЕАЛИЗОВАНО)
	-- -- 230 - Пиры в соседних сетях по AS сети, между /21 и /16
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
	-- 			and peers.ip << ANY (
	-- 				select networks.network from networks
	-- 					where masklen(networks.network) between 16 and 21
	-- 					and asn = (
	-- 						select networks.asn from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 			) limit required_peers_num
	-- 	) as conn_data,
	-- (select 230 as type) as type_data
	-- );

	-- -- 300 - Пиры в соседних сетях по AS сети и городу
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
	-- 			and peers.ip << ANY (
	-- 				select networks.network from networks
	-- 					where networks.asn = (
	-- 						select networks.asn from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 					and networks.city = (
	-- 						select networks.city from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 			) limit required_peers_num
	-- 	) as conn_data,
	-- (select 300 as type) as type_data
	-- );

	-- -- 310 - Пиры в соседних сетях по AS сети и региону
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
	-- 			and peers.ip << ANY (
	-- 				select networks.network from networks
	-- 					where networks.asn = (
	-- 						select networks.asn from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 					and networks.region = (
	-- 						select networks.region from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 			) limit required_peers_num
	-- 	) as conn_data,
	-- (select 310 as type) as type_data
	-- );

	-- -- 400 - Пиры в соседних сетях по городу
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
	-- 			and peers.ip << ANY (
	-- 				select networks.network from networks
	-- 					where networks.city = (
	-- 						select networks.city from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 			) limit required_peers_num
	-- 	) as conn_data,
	-- (select 400 as type) as type_data
	-- );

	-- -- 410 - Пиры в соседних сетях по региону
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
	-- 			and peers.ip << ANY (
	-- 				select networks.network from networks
	-- 					where networks.region = (
	-- 						select networks.region from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 			) limit required_peers_num
	-- 	) as conn_data,
	-- (select 410 as type) as type_data
	-- );

	-- -- 420 - Пиры в соседних сетях по стране
	-- insert into tmp_peer_list (
	-- 	select conn_data.conn_id,type_data.type from (
	-- 		select peers.conn_id from peers
	-- 			where peers.channel_id = my_channel_id
	-- 			and peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
	-- 			and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
	-- 			and peers.ip << ANY (
	-- 				select networks.network from networks
	-- 					where networks.country = (
	-- 						select networks.country from networks where (
	-- 							select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
	-- 						order by networks.network desc limit 1
	-- 					)
	-- 			) limit required_peers_num
	-- 	) as conn_data,
	-- (select 420 as type) as type_data
	-- );

	RETURN QUERY
		select * from tmp_peer_list;
	drop table tmp_exclude_conn_id;
	drop table tmp_peer_list;
END
$$ LANGUAGE plpgsql;


