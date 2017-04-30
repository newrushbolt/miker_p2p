DROP DATABASE IF EXISTS p2p;
CREATE DATABASE p2p;
USE `p2p`;

DROP TABLE IF EXISTS peer_state;
CREATE TABLE `peer_state` (
  `conn_id` varchar(45) NOT NULL,
  `channel_id` varchar(45) NOT NULL,
  `gg_id` varchar(45) DEFAULT NULL,
  `last_update` int(10) unsigned NOT NULL,
  `ip` int(10) unsigned NOT NULL,
  `network` int(10) unsigned NOT NULL,
  `netmask` int(10) unsigned NOT NULL,
  `asn` int(10) unsigned NOT NULL,
  `country` varchar(45) DEFAULT NULL,
  `region` varchar(45) DEFAULT NULL,
  `city` varchar(45) DEFAULT NULL,
  UNIQUE KEY `conn_id` (`conn_id`) USING BTREE,
  UNIQUE KEY `uniq_id` (`conn_id`,`channel_id`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ip_bad_peers;
CREATE TABLE `ip_bad_peers` (
  `conn_id` varchar(45) NOT NULL,
  `channel_id` varchar(45) NOT NULL,
  `gg_id` varchar(45) DEFAULT NULL,
  `last_update` int(10) unsigned NOT NULL,
  `ip` int(10) unsigned NOT NULL,
  UNIQUE KEY `conn_id` (`conn_id`) USING BTREE,
  UNIQUE KEY `uniq_id` (`conn_id`,`channel_id`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS peer_load_5;
CREATE TABLE `peer_load_5` (
  `seed_conn_id` varchar(45) NOT NULL,
  `ts` int(10) unsigned NOT NULL,
  `peer_conn_id` varchar(45) NOT NULL,
  `bytes` int(10) unsigned NOT NULL,
  UNIQUE KEY `uniq_ts_ids` (`seed_conn_id`,`ts`,`peer_conn_id`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS peer_bad_30;
CREATE TABLE `peer_bad_30` (
  `seed_conn_id` varchar(45) NOT NULL,
  `ts` int(10) unsigned NOT NULL,
  `peer_conn_id` varchar(45) NOT NULL,
  UNIQUE KEY `uniq_ts_ids` (`seed_conn_id`,`ts`,`peer_conn_id`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS net_bad_30;
CREATE TABLE `net_bad_30` (
  `seed_network` int(10) unsigned NOT NULL,
  `seed_netmask` int(10) unsigned NOT NULL,
  `ts` int(10) unsigned NOT NULL,
  `peer_network` int(10) unsigned NOT NULL,
  `peer_netmask` int(10) unsigned NOT NULL,
  UNIQUE KEY `uniq_ts_ids` (`seed_network`,`seed_netmask`,`ts`,`peer_network`,`peer_netmask`) USING BTREE,
  PRIMARY KEY `seed_net` (`seed_network`,`seed_netmask`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS worker_counters;
CREATE TABLE `worker_counters` (
  `worker` varchar(45) NOT NULL,
  `type` varchar(45) NOT NULL,
  `count` int(10) unsigned,
  UNIQUE KEY `uniq_worker` (`worker`,`type`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS peer_lists;
CREATE TABLE `peer_lists` (
  `conn_id` varchar(45) UNIQUE NOT NULL,
  `ts` int(10) unsigned NOT NULL,
  `peer_list` varchar(255) NOT NULL,
  PRIMARY KEY `conn_id_ts` (`conn_id`,`ts`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP USER IF EXISTS 'p2p'@'localhost';
CREATE USER 'p2p'@'localhost' IDENTIFIED BY 'wb5nv6d8';
SET SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';
GRANT ALL ON `p2p`.* TO 'p2p'@localhost;
