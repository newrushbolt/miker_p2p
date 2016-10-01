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

DROP USER 'p2p'@'localhost';
CREATE USER 'p2p'@'localhost' IDENTIFIED BY 'wb5nv6d8';
SET SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';
GRANT ALL ON `p2p`.* TO 'p2p'@localhost;
