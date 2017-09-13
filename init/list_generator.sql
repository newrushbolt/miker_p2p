-- ###Генератор
-- ##Типы эксклудов
-- 0 - сам пир
-- 1 - перегруженные пиры
-- 2 - сбойные по пир-пир таблице пиры
-- ##Типы пиров в списке
-- 100 - хорошие пиры + город
-- 110 - хорошие пиры + регион
-- 120 - "хорошие сети" + город
-- 130 - "хорошие сети" + регион
-- 200  - ближайщая сеть,не крупнее /21
-- 210 - сети(2 уровня) и AS(по ближайшей сети), не крупнее /21
-- 220 - сети в пиринге, в максимум в два хопа(НЕ РЕАЛИЗОВАНО)
-- 230 - сети между /21 и /16
-- 300 - по ASN и городу
-- 310 - по ASN и региону
-- 400 - по городу
-- 410 - по региону
-- 420 - по стране
CREATE OR REPLACE FUNCTION genereate_peer_list(my_conn_id varchar(45), my_channel_id varchar(45)) RETURNS text AS $$
	-- Создаем временную таблицу для исключения уже добавленных пиров
	create temp table tmp_sessionid1_exclude_conn_id (
		conn_id varchar(45) UNIQUE NOT NULL,
		type smallint NOT NULL
	);
	-- Создаем временную таблицу для списка пиров
	create temp table tmp_sessionid1_peer_list (
		conn_id varchar(45) UNIQUE NOT NULL,
		type smallint NOT NULL
	);

	-- Добавляем в исключения себя
	insert into tmp_sessionid1_exclude_conn_id values(my_conn_id,0);

	-- Добавляем в исключения перегруженные пиры
	insert into tmp_sessionid1_exclude_conn_id (
		select conn_id from (
			select conn_id from peers 
				where channel_id=my_channel_id 
				and (select count(distinct peer_conn_id) from peers_good where conn_id=peers.conn_id) > (select slots_per_seed from channels_settings)
		) as conn_data
		full join  (select 1 as type) as type_data on true where conn_data.conn_id != ''
	);

	-- 100 - хорошие пиры + город
	-- select conn_id,bytes/ltime as speed FROM peers_good where peer_conn_id=my_conn_id;

	-- 110 - хорошие пиры + регион

	-- 120 - "хорошие сети" + город
	insert into tmp_sessionid1_peer_list (
		select conn_id from (
			select conn_id from peers 
				where conn_id NOT IN (select conn_id from tmp_sessionid1_exclude_conn_id) 
				and ip << ANY (
					select network from networks 
						where network in (
							select network from networks_good_stats_30 where peer_network << my_conn_id
						) 
						and city = (
							select city from networks where network << (select ip from peers where conn_id = my_conn_id) 
						)
		) as conn_data 
		full join (select 120 as type) as type_data on true where conn_data.conn_id != ''
	);

	-- 130 - "хорошие сети" + регион
	insert into tmp_sessionid1_peer_list (
		select conn_id from (
			select conn_id from peers 
				where conn_id NOT IN (select conn_id from tmp_sessionid1_exclude_conn_id) 
				and ip << ANY (
					select network from networks 
						where network in (
							select network from networks_good_stats_30 where peer_network << (
								select ip from peers where conn_id = my_conn_id)
						) 
						and city = (
							select region from networks where network << (select ip from peers where conn_id = my_conn_id)
						)
				)
		) as conn_data 
		full join (select 130 as type) as type_data on true where conn_data.conn_id != ''
	);

	-- 200  - ближайщая сеть,не крупнее /23
	insert into tmp_sessionid1_peer_list (
		select conn_id from (
			select conn_id from peers 
				where conn_id NOT IN (select conn_id from tmp_sessionid1_exclude_conn_id) 
				and ip << ANY (
					select network from networks 
	 					where network >> ANY (select ip from peers where conn_id=my_conn_id)
	 					and masklen(network) =<23
						order by network desc limit 1
				)
		) as conn_data 
		full join (select 200 as type) as type_data on true where conn_data.conn_id != ''
	);

	-- 210 - сети(2 уровня) и AS(по ближайшей сети), не крупнее /21
	insert into tmp_sessionid1_peer_list (
		select conn_id from (
			select conn_id from peers 
				where conn_id NOT IN (select conn_id from tmp_sessionid1_exclude_conn_id) 
				and ip << ANY (
					select network from networks 
	 					where network >> ANY (select ip from peers where conn_id=my_conn_id)
	 					and masklen(network) =< 21
	 					and asn = (
	 						select asn from networks where (
	 							select ip from peers where conn_id=my_conn_id) << network 
	 						order by network desc limit 1
						)
				)
			order by network desc limit 2
		) as conn_data 
		full join (select 210 as type) as type_data on true where conn_data.conn_id != ''
	);

	-- 220 - сети в пиринге, в максимум в два хопа(НЕ РЕАЛИЗОВАНО)
	-- 230 - сети между /21 и /16
	-- 300 - по ASN и городу
	-- 310 - по ASN и региону
	-- 400 - по городу
	-- 410 - по региону
	-- 420 - по стране

	select * from tmp_sessionid1_peer_list;
$$ LANGUAGE SQL;
