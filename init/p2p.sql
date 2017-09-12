DROP TABLE IF EXISTS peers CASCADE;
CREATE TABLE peers (
  conn_id varchar(45) UNIQUE NOT NULL,
  channel_id varchar(45) NOT NULL,
  gg_id varchar(45) DEFAULT NULL,
  ip inet NOT NULL,
  CONSTRAINT connid_channel PRIMARY KEY (conn_id,channel_id)
);

DROP TABLE IF EXISTS peers_updates CASCADE;
CREATE TABLE peers_updates (
  conn_id varchar(45) UNIQUE PRIMARY KEY NOT NULL,
  last_update timestamp NOT NULL,
  CONSTRAINT peers_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id)
);

DROP TABLE IF EXISTS peers_lists CASCADE;
CREATE TABLE peers_lists (
  conn_id varchar(45) NOT NULL,
  ts timestamp NOT NULL,
  peers_list text NOT NULL,
  CONSTRAINT connid_ts PRIMARY KEY (conn_id,ts),
  CONSTRAINT peers_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id)
);

DROP TABLE IF EXISTS channels_slots CASCADE;
CREATE TABLE channels_slots (
  channel_id varchar(45) UNIQUE PRIMARY KEY NOT NULL,
  slot_limit int NOT NULL
);

DROP TABLE IF EXISTS networks CASCADE;
CREATE TABLE networks (
  network cidr PRIMARY KEY NOT NULL,
  asn int NOT NULL,
  country varchar(45) DEFAULT NULL,
  region varchar(45) DEFAULT NULL,
  city varchar(45) DEFAULT NULL,
  CONSTRAINT network_asn UNIQUE (network,asn)
);

DROP TABLE IF EXISTS peers_good CASCADE;
CREATE TABLE peers_good (
  conn_id varchar(45) PRIMARY KEY NOT NULL,
  peers_conn_id varchar(45) NOT NULL,
  ts int NOT NULL,
  bytes int NOT NULL,
  ltime int DEFAULT NULL,
  CONSTRAINT seeds_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id),
  CONSTRAINT peers_conn_id FOREIGN KEY (peer_conn_id) REFERENCES peers (conn_id),
  CONSTRAINT seed_peer_ts UNIQUE (conn_id,peers_conn_id,ts)
);

DROP TABLE IF EXISTS ip_good CASCADE;
CREATE TABLE ip_good (
  ip inet PRIMARY KEY NOT NULL,
  peer_ip inet NOT NULL,
  ts int NOT NULL,
  bytes int NOT NULL,
  ltime int DEFAULT NULL,
  CONSTRAINT seed_peer_ts UNIQUE (ip,peers_ip,ts)
);

DROP TABLE IF EXISTS peers_bad CASCADE;
CREATE TABLE peers_bad (
  conn_id varchar(45) PRIMARY KEY NOT NULL,
  peers_conn_id varchar(45) NOT NULL,
  ts int NOT NULL,
  CONSTRAINT seeds_conn_id FOREIGN KEY (conn_id) REFERENCES peers (conn_id),
  CONSTRAINT peers_conn_id FOREIGN KEY (peer_conn_id) REFERENCES peers (conn_id),
  CONSTRAINT seed_peer_ts UNIQUE (conn_id,peers_conn_id,ts)
);

DROP TABLE IF EXISTS ip_bad CASCADE;
CREATE TABLE ip_bad (
  ip inet PRIMARY KEY NOT NULL,
  peer_ip inet NOT NULL,
  ts int NOT NULL,
  CONSTRAINT seed_peer_ts UNIQUE (ip,peers_ip,ts)
);

DROP TABLE IF EXISTS networks_good_stats_30 CASCADE;
CREATE TABLE networks_good_stats_30 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);

DROP TABLE IF EXISTS networks_good_stats_720 CASCADE;
CREATE TABLE networks_good_stats_720 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);

DROP TABLE IF EXISTS networks_bad_stats_30 CASCADE;
CREATE TABLE networks_bad_stats_30 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);

DROP TABLE IF EXISTS networks_bad_stats_720 CASCADE;
CREATE TABLE networks_bad_stats_720 (
  network cidr PRIMARY KEY NOT NULL,
  peer_network cidr NOT NULL,
  CONSTRAINT network FOREIGN KEY (network) REFERENCES networks (network),
  CONSTRAINT peer_network FOREIGN KEY (peer_network) REFERENCES networks (network)
);
