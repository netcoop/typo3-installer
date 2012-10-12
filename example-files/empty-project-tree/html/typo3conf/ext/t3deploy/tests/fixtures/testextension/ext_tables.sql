CREATE TABLE tx_testextension (
	id int(11) NOT NULL auto_increment,
	identifier varchar(250) NOT NULL default '',
	tag varchar(250) NOT NULL default '',
	PRIMARY KEY  (`id`),
	KEY `cache_id` (`identifier`)
	KEY `cache_tag` (`tag`)	
) ENGINE=InnoDB;

CREATE TABLE pages (
	tx_testextension_field varchar(64) NOT NULL default '',
	alias varchar(33)  NOT NULL default ''
);