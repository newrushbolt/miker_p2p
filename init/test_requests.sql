truncate table channels_slots CASCADE;
truncate table peers CASCADE;
truncate table networks CASCADE;

insert into channels_slots values('channel1',10);
insert into networks values('185.40.152.0/24',1,'RU','NW','SPB'),('185.40.153.0/24',1,'RU','EA','BEL'),	('185.40.148.0/16',1,'RU','MR','MOS');
insert into peers values('connid1','channel1','ggid1','185.40.152.12'),('connid2','channel1','ggid2','185.40.152.11'),('connid3','channel1','ggid3','185.40.152.10'),('connid4','channel1','ggid4','185.40.153.12');