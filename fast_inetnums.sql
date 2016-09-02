/*!40101 SET NAMES utf8 */;
/*!40103 SET TIME_ZONE='+00:00' */;

DROP TABLE IF EXISTS `fast_inetnums`;
CREATE TABLE `fast_inetnums` (
  `network` int(10) unsigned NOT NULL,
  `netmask` int(10) unsigned NOT NULL,
  `asn` int(10) unsigned NOT NULL,
  PRIMARY KEY (`network`,`netmask`,`asn`) using btree
) ENGINE=MEMORY DEFAULT CHARSET=utf8;
