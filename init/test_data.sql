-- Чистим таблицы
truncate table channels_slots CASCADE;
truncate table peers CASCADE;
truncate table networks CASCADE;
truncate table peers_good CASCADE;

-- Инжектим тестовые данные
insert into channels_settings values
	('channel1',3,10);

insert into networks values
	('185.40.152.0/24',1,'RU','NW','SPB'),
	('185.40.153.0/24',1,'RU','EA','BEL'),
	('185.40.0.0/16',1,'RU','MR','MOS');

insert into peers values
	('connid1','channel1','ggid1','185.40.152.12'),
	('connid2','channel1','ggid2','185.40.152.11'),
	('connid3','channel1','ggid3','185.40.152.10'),
	('connid4','channel1','ggid4','185.40.153.12');

insert into peers_good values
	('connid2','connid1',111,200,1),
	('connid2','connid3',111,300,2),
	('connid2','connid4',111,900,6);

