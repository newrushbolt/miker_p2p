-- Чистим таблицы
truncate table channels_slots CASCADE;
truncate table peers CASCADE;
truncate table networks CASCADE;

-- Инжектим тестовые данные
insert into channels_slots values('channel1',10);
insert into networks values('185.40.152.0/24',1,'RU','NW','SPB'),('185.40.153.0/24',1,'RU','EA','BEL'),	('185.40.0.0/16',1,'RU','MR','MOS');
insert into peers values('connid1','channel1','ggid1','185.40.152.12'),('connid2','channel1','ggid2','185.40.152.11'),('connid3','channel1','ggid3','185.40.152.10'),('connid4','channel1','ggid4','185.40.153.12');
insert into peers_good values('connid2','connid1',111,200,1),('connid2','connid3',111,200,1),('connid2','connid4',111,200,1);

-- ###Генератор
-- ##Типы эксклудов
-- 0 - сам пир
-- 1 - перегруженные пиры
-- 2 - сбойные по пир-пир таблице пиры
-- ##Типы пиров в списке
-- 100 - хорошие пиры + регион
-- 110 - "хорошие сети" + город
-- 120 - "хорошие сети" + регион
-- 40  - ближайщая сеть,не крупнее /21
-- 50 - сети(2 уровня) и AS(по ближайшей сети), не крупнее /21
-- 30 - сети в пиринге, в максимум в два хопа(НЕ РЕАЛИЗОВАНО)
-- 40 - сети между /21 и /16
-- 50 - по ASN и городу
-- 60 - по ASN и региону
-- 70 - по городу
-- 

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
insert into tmp_sessionid1_exclude_conn_id values('connid1',0);

-- Добавляем в исключения перегруженные пиры
insert into tmp_sessionid1_exclude_conn_id (
	select * from (
		select conn_id from peers 
			where channel_id='channel1' 
			and (select count(distinct peer_conn_id) from peers_good where conn_id=peers.conn_id) > (select slot_limit from channels_slots)
	) as conn_data
	full join lateral (select 1 as type) as type_data on true
);

-- Получаем список сетей, в которых состоит пир connid1 в порядке убывания
select * from network where network >> (select ip from peers where conn_id='connid1') order by network desc;

-- Получаем соседних пиров в ближайшей сетке
select conn_id from peers
	where channel_id = 'channel1'
 	and ip << (
 		select network from networks 
 			where network >> ANY (select ip from peers where conn_id='connid1')
		order by network desc limit 1
	)
	and conn_id NOT IN (select conn_id from tmp_sessionid1_exclude_conn_id)
;

-- Получаем соседних пиров во всех сетках(не более 3), начиная с наиболее специфичной сети
select conn_id from peers where
	ip << ANY (
		select network from networks where network >> ANY (
			select ip from peers where conn_id='connid1') order by network desc limit 1
		)
	and conn_id NOT IN (select conn_id from tmp_sessionid1_exclude_conn_id)
;

-- Сносим временную таблицу
drop table tmp_sessionid1_exclude_conn_id;

