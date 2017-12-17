-- Чистим таблицы
truncate table channels_settings CASCADE;
truncate table peers CASCADE;
truncate table networks CASCADE;
truncate table peers_good CASCADE;

-- Инжектим тестовые данные
insert into channels_settings values ('channel1');

insert into networks values
	('185.40.152.0/24',1,'RU','NW','SPB'),
	('185.40.153.0/24',1,'RU','NW','SPB'),
	('181.40.153.0/24',2,'RU','NW','SPB'),
	('180.40.153.0/24',2,'RU','NW','VIB'),
	('179.40.153.0/24',2,'RU','MR','MOS'),
	('185.42.0.0/17',1,'RU','NW','SPB'),
	('182.0.0.0/8',1,'RU','NW','SPB'),
	('183.0.0.0/8',1,'RU','NW','VIB'),
	('185.40.160.0/20',1,'RU','MR','MOS'),
	('185.40.0.0/16',1,'RU','MR','MOS');

insert into peers values
	-- Test user
	('connid1','channel1','ggid1','185.40.152.12'),
	-- His closest neighbor
	('connid2','channel1','ggid2','185.40.152.11'),
	-- His neighbor from close network, same as,region,country,city
	('connid3','channel1','ggid3','185.40.153.14'),
	-- His neighbor from 8 network, same as,region,country,city
	('connid4','channel1','ggid4','182.42.1.1'),
	-- His neighbor from 8 network, same as,country,region
	('connid5','channel1','ggid5','183.42.1.1'),
	-- His neighbor from 20 network, same as,country
	('connid6','channel1','ggid6','185.40.160.2'),
	-- His neighbor from 16 network, same as,country
	('connid7','channel1','ggid7','185.42.0.1'),
	-- His neighbor from same region,country,city
	('connid8','channel1','ggid8','181.40.153.11'),
	-- His neighbor from same region,country
	('connid9','channel1','ggid9','180.40.153.11'),
	-- His neighbor from same country
	('connid10','channel1','ggid10','179.40.153.11');

-- insert into peers_good values
-- 	('connid2','connid1',111,200,1),
-- 	('connid2','connid3',111,300,2),
-- 	('connid2','connid4',111,900,6);

insert into peers_v2 values ('connid1','channel1','ggid1','185.40.152.12');
insert into peers_v2 values ('connid1','channel3','ggid1','185.40.152.12');
insert into peers_v2 values ('connid1','channel2','ggid1','185.40.152.12');
