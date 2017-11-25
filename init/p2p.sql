DROP TABLE IF EXISTS channels_settings CASCADE;
DROP TABLE IF EXISTS networks CASCADE;
DROP TABLE IF EXISTS peers CASCADE;
DROP TABLE IF EXISTS peers_updates CASCADE;
DROP TABLE IF EXISTS peers_lists CASCADE;
DROP TABLE IF EXISTS peers_good CASCADE;
DROP TABLE IF EXISTS ip_good CASCADE;
DROP TABLE IF EXISTS peers_bad CASCADE;
DROP TABLE IF EXISTS ip_bad CASCADE;
DROP TABLE IF EXISTS networks_good_stats_30 CASCADE;
DROP TABLE IF EXISTS networks_good_stats_720 CASCADE;
DROP TABLE IF EXISTS networks_bad_stats_30 CASCADE;
DROP TABLE IF EXISTS networks_bad_stats_720 CASCADE;

-- Добавляет пользователя p2p
DROP USER IF EXISTS p2p;
CREATE USER p2p with password 'p2p' login;

-- настройки каналов, обновляет их p2p-сервис
CREATE TABLE channels_settings (
  channel_id varchar(45) UNIQUE PRIMARY KEY NOT NULL,
  slots_per_seed int NOT NULL,
  seeds_in_list int NOT NULL
);
ALTER TABLE channels_settings OWNER to p2p;

-- список сетей с гео и ip информацией, обновляется отдельным приложением
CREATE TABLE networks (
  network cidr PRIMARY KEY NOT NULL,
  asn int NOT NULL,
  country varchar(45) DEFAULT NULL,
  region varchar(45) DEFAULT NULL,
  city varchar(45) DEFAULT NULL,
  CONSTRAINT networks_network_asn UNIQUE (network,asn)
);
ALTER TABLE networks OWNER to p2p;

-- онлайн-пиры, обновляются с запросов на подключение, логов, и системой очистки устаревших/зависших пиров
CREATE TABLE peers (
  conn_id varchar(45) UNIQUE NOT NULL,
  channel_id varchar(45) NOT NULL,
  gg_id varchar(45) DEFAULT NULL,
  ip inet NOT NULL,
  CONSTRAINT peers_connid_channel PRIMARY KEY (conn_id,channel_id),
  CONSTRAINT peers_channelid_slot FOREIGN KEY (channel_id) REFERENCES channels_settings (channel_id)
);
ALTER TABLE peers OWNER to p2p;

-- timestamp пиров, обновляются с логов
CREATE TABLE peers_updates (
  conn_id varchar(45) UNIQUE PRIMARY KEY NOT NULL,
  last_update timestamp NOT NULL,
  CONSTRAINT peers_updates_peer_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id)
);
ALTER TABLE peers_updates OWNER to p2p;

-- списки пиров в json, создаются генератором
CREATE TABLE peers_lists (
  conn_id varchar(45) NOT NULL,
  ts timestamp NOT NULL,
  peers_list text NOT NULL,
  CONSTRAINT peers_lists_connid_ts PRIMARY KEY (conn_id,ts),
  CONSTRAINT peers_lists_peer_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id)
);
ALTER TABLE peers_lists OWNER to p2p;

-- моментальная статистика успешных скачиваний по CONN_ID, обновляется с логов
CREATE TABLE peers_good (
  conn_id varchar(45) NOT NULL,
  peer_conn_id varchar(45) NOT NULL,
  ts int NOT NULL,
  bytes int NOT NULL,
  ltime int DEFAULT NULL,
  CONSTRAINT peers_good_seed_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id),
  CONSTRAINT peers_good_peer_conn_id FOREIGN KEY (peer_conn_id) REFERENCES peers (conn_id),
  CONSTRAINT peers_good_seed_peer_ts PRIMARY KEY (conn_id,peer_conn_id,ts)
);
ALTER TABLE peers_good OWNER to p2p;

-- моментальная статистика успешных скачиваний по IP, обновляется с логов
CREATE TABLE ip_good (
  ip inet PRIMARY KEY NOT NULL,
  peer_ip inet NOT NULL,
  ts int NOT NULL,
  bytes int NOT NULL,
  ltime int DEFAULT NULL,
  CONSTRAINT ip_good_seed_peer_ts UNIQUE (ip,peer_ip,ts)
);
ALTER TABLE ip_good OWNER to p2p;

-- моментальная статистика провальных скачиваний по CONN_ID, обновляется с логов
CREATE TABLE peers_bad (
  conn_id varchar(45) PRIMARY KEY NOT NULL,
  peer_conn_id varchar(45) NOT NULL,
  ts int NOT NULL,
  CONSTRAINT peers_bad_seed_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id),
  CONSTRAINT peers_bad_peer_conn_id FOREIGN KEY (peer_conn_id) REFERENCES peers (conn_id),
  CONSTRAINT peers_bad_seed_peer_ts UNIQUE (conn_id,peer_conn_id,ts)
);
ALTER TABLE peers_bad OWNER to p2p;

-- моментальная статистика провальных скачиваний по IP, обновляется с логов
CREATE TABLE ip_bad (
  ip inet PRIMARY KEY NOT NULL,
  peer_ip inet NOT NULL,
  ts int NOT NULL,
  CONSTRAINT ip_bad_seed_peer_ts UNIQUE (ip,peer_ip,ts)
);
ALTER TABLE ip_bad OWNER to p2p;

-- накопительная статистика успешных скачиваний между сетями, выборка за полчаса, обновляется с ip_good
CREATE TABLE networks_good_stats_30 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT networks_good_stats_30_network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT networks_good_stats_30_peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);
ALTER TABLE networks_good_stats_30 OWNER to p2p;

-- накопительная статистика успешных скачиваний между сетями, выборка за сутки, обновляется с ip_good
CREATE TABLE networks_good_stats_720 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT networks_good_stats_720_network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT networks_good_stats_720_peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);
ALTER TABLE networks_good_stats_720 OWNER to p2p;

-- накопительная статистика провальных скачиваний между сетями, выборка за полчаса, обновляется с ip_bad
CREATE TABLE networks_bad_stats_30 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT networks_bad_stats_30_network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT networks_bad_stats_30_peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);
ALTER TABLE networks_bad_stats_30 OWNER to p2p;

-- накопительная статистика провальных скачиваний между сетями, выборка за час, обновляется с ip_bad
CREATE TABLE networks_bad_stats_720 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT networks_bad_stats_720_network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT networks_bad_stats_720_peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);
ALTER TABLE networks_bad_stats_720 OWNER to p2p;
