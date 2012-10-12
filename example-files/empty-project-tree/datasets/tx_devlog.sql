--
-- Table structure for table `tx_devlog`
--

CREATE TABLE IF NOT EXISTS `tx_devlog` (
  `uid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(11) unsigned NOT NULL DEFAULT '0',
  `crdate` int(11) unsigned NOT NULL DEFAULT '0',
  `crmsec` bigint(11) unsigned NOT NULL DEFAULT '0',
  `cruser_id` int(11) unsigned NOT NULL DEFAULT '0',
  `severity` int(11) NOT NULL DEFAULT '0',
  `extkey` varchar(40) NOT NULL DEFAULT '',
  `msg` text NOT NULL,
  `location` varchar(255) NOT NULL DEFAULT '',
  `line` int(11) NOT NULL DEFAULT '0',
  `data_var` mediumtext NOT NULL,
  PRIMARY KEY (`uid`),
  KEY `parent` (`pid`),
  KEY `crdate` (`crdate`),
  KEY `crmsec` (`crmsec`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=234 ;

