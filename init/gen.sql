CREATE OR REPLACE FUNCTION genereate_peer_list(my_conn_id varchar(45), my_channel_id varchar(45)) RETURNS TABLE(conn_id varchar(45), type smallint) AS $$
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
	insert into tmp_exclude_conn_id (
		select conn_data.conn_id,type_data.type from (select * from peers
				where peers.channel_id = my_channel_id
				and (select count(distinct peer_conn_id) from peers_good where peers_good.conn_id=peers.conn_id) > (select slots_per_seed from channels_settings)) as conn_data,
		(select 1 as type) as type_data
	);

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
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and ip << ANY (
					select networks.network from networks
	 					where network >> ANY (select peers.ip from peers where peers.conn_id=my_conn_id)
	 					and masklen(network) >= 23
						order by network desc limit 1
				)
		) conn_data,
		(select 200 as type) as type_data
	);

	-- -- 210 - Пиры в соседних сетях по AS сети, не крупнее /21
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
				and peers.ip << ANY (
					select networks.network from networks
	 					-- where networks.network >> ANY (select peers.ip from peers where peers.conn_id=my_conn_id)
						where masklen(networks.network) > 21
						and asn = (
							select networks.asn from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
				)
		) as conn_data,
		(select 210 as type) as type_data
	);

	-- 220 - сети в пиринге, в максимум в два хопа(НЕ РЕАЛИЗОВАНО)
	-- 230 - Пиры в соседних сетях по AS сети, между /21 и /16
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
				and peers.ip << ANY (
					select networks.network from networks
						where masklen(networks.network) between 16 and 21
						and asn = (
							select networks.asn from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
				)
		) as conn_data,
	(select 230 as type) as type_data
	);

	-- 300 - Пиры в соседних сетях по AS сети и городу
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
				and peers.ip << ANY (
					select networks.network from networks
						where networks.asn = (
							select networks.asn from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
						and networks.city = (
							select networks.city from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
				)
		) as conn_data,
	(select 300 as type) as type_data
	);

	-- 310 - Пиры в соседних сетях по AS сети и региону
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
				and peers.ip << ANY (
					select networks.network from networks
						where networks.asn = (
							select networks.asn from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
						and networks.region = (
							select networks.region from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
				)
		) as conn_data,
	(select 310 as type) as type_data
	);

	-- 400 - Пиры в соседних сетях по городу
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
				and peers.ip << ANY (
					select networks.network from networks
						where networks.city = (
							select networks.city from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
				)
		) as conn_data,
	(select 400 as type) as type_data
	);

	-- 410 - Пиры в соседних сетях по региону
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
				and peers.ip << ANY (
					select networks.network from networks
						where networks.region = (
							select networks.region from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
				)
		) as conn_data,
	(select 410 as type) as type_data
	);

	-- 420 - Пиры в соседних сетях по стране
	insert into tmp_peer_list (
		select conn_data.conn_id,type_data.type from (
			select peers.conn_id from peers
				where peers.conn_id NOT IN (select tmp_exclude_conn_id.conn_id from tmp_exclude_conn_id)
				and peers.conn_id NOT IN (select tmp_peer_list.conn_id from tmp_peer_list)
				and peers.ip << ANY (
					select networks.network from networks
						where networks.country = (
							select networks.country from networks where (
								select peers.ip from peers where peers.conn_id=my_conn_id) << networks.network
							order by networks.network desc limit 1
						)
				)
		) as conn_data,
	(select 420 as type) as type_data
	);

	RETURN QUERY
		select * from tmp_peer_list;
END
$$ LANGUAGE plpgsql;


