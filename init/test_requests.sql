#чистим таблицы
truncate table channels_slots CASCADE;
truncate table peers CASCADE;
truncate table networks CASCADE;

#инжектим тестовые данные
insert into channels_slots values('channel1',10);
insert into networks values('185.40.152.0/24',1,'RU','NW','SPB'),('185.40.153.0/24',1,'RU','EA','BEL'),	('185.40.0.0/16',1,'RU','MR','MOS');
insert into peers values('connid1','channel1','ggid1','185.40.152.12'),('connid2','channel1','ggid2','185.40.152.11'),('connid3','channel1','ggid3','185.40.152.10'),('connid4','channel1','ggid4','185.40.153.12');

#получаем список сетей, в которых состоит пир connid1 в порядке убывания
select * from network where network >> (select ip from peers where conn_id='connid1') order by network desc;

#получаем соседних пиров в ближайшей сетке
select * from peers where
ip << (select network from networks where network >> ANY (select ip from peers where conn_id='connid1') order by network desc limit 1);


#получаем соседних пиров во всех сетках, начиная с наиболее специфичной сети
select * from peers where
ip << ANY (select network from networks where network >> ANY (select ip from peers where conn_id='connid1') order by network desc);
