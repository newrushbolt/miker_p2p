CREATE DATABASE  IF NOT EXISTS `p2p`;
USE `p2p`;

DROP TABLE IF EXISTS `peer_state`;
CREATE TABLE `peer_state` (
  `webrtc_id` varchar(45) NOT NULL,
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
  UNIQUE KEY `webrtc_id` (`webrtc_id`),
  UNIQUE KEY `uniq_id` (`webrtc_id`,`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ip_bad_peers`;
CREATE TABLE `ip_bad_peers` (
  `webrtc_id` varchar(45) NOT NULL,
  `channel_id` varchar(45) NOT NULL,
  `gg_id` varchar(45) DEFAULT NULL,
  `last_update` int(10) unsigned NOT NULL,
  `ip` int(10) unsigned NOT NULL,
  UNIQUE KEY `webrtc_id` (`webrtc_id`),
  UNIQUE KEY `uniq_id` (`webrtc_id`,`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `peer_load_5`;
CREATE TABLE `peer_load_5` (
  `seed_webrtc_id` varchar(45) NOT NULL,
  `ts` int(10) unsigned NOT NULL,
  `peer_webrtc_id` varchar(45) NOT NULL,
  `bytes` int(10) unsigned NOT NULL,
  UNIQUE KEY `uniq_ts_ids` (`seed_webrtc_id`,`ts`,`peer_webrtc_id`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8 

DROP TABLE IF EXISTS `peer_bad_30`;
CREATE TABLE `peer_bad_30` (
  `seed_webrtc_id` varchar(45) NOT NULL,
  `ts` int(10) unsigned NOT NULL,
  `peer_webrtc_id` varchar(45) NOT NULL,
  UNIQUE KEY `uniq_ts_ids` (`seed_webrtc_id`,`ts`,`peer_webrtc_id`) USING BTREE
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS net_bad_30`;
CREATE TABLE `net_bad_30` (
  `seed_network` int(10) unsigned NOT NULL,
  `seed_netmask` int(10) unsigned NOT NULL,
  `ts` int(10) unsigned NOT NULL,
  `peer_network` int(10) unsigned NOT NULL,
  `peer_netmask` int(10) unsigned NOT NULL,
  UNIQUE KEY `uniq_ts_ids` (`seed_network`,`seed_netmask`,`ts`,`peer_network`,`peer_netmask`) USING BTREE,
  PRIMARY KEY `seed_net` (`seed_network`,`seed_netmask`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;


DROP USER 'p2p'@'localhost';
CREATE USER 'p2p'@'localhost' IDENTIFIED BY 'wb5nv6d8';
SET SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';
GRANT ALL ON `p2p`.* TO 'p2p'@localhost;
