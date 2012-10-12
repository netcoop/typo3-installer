<?php

########################################################################
# Extension Manager/Repository config file for ext "t3deploy".
#
# Auto generated 15-07-2012 09:11
#
# Manual updates:
# Only the data in the array - everything else is removed by next
# writing. "version" and "dependencies" must not be touched!
########################################################################

$EM_CONF[$_EXTKEY] = array(
	'title' => 't3deploy TYPO3 dispatcher',
	'description' => '',
	'category' => 'be',
	'shy' => 0,
	'version' => '0.0.2+Cache',
	'dependencies' => '',
	'conflicts' => '',
	'priority' => '',
	'loadOrder' => '',
	'module' => '',
	'state' => 'alpha',
	'uploadfolder' => 0,
	'createDirs' => '',
	'modify_tables' => '',
	'clearcacheonload' => 0,
	'lockType' => '',
	'author' => 'AOE media GmbH',
	'author_email' => 'dev@aoemedia.de',
	'author_company' => '',
	'CGLcompliance' => '',
	'CGLcompliance_note' => '',
	'constraints' => array(
		'depends' => array(
			'typo3' => '4.2.0-0.0.0',
		),
		'conflicts' => array(
		),
		'suggests' => array(
		),
	),
	'_md5_values_when_last_written' => 'a:12:{s:12:"dispatch.php";s:4:"b252";s:12:"ext_icon.gif";s:4:"f19a";s:17:"ext_localconf.php";s:4:"ee9f";s:14:"ext_tables.php";s:4:"845e";s:45:"classes/class.tx_t3deploy_cacheController.php";s:4:"2153";s:48:"classes/class.tx_t3deploy_databaseController.php";s:4:"dcd8";s:38:"classes/class.tx_t3deploy_dispatch.php";s:4:"2361";s:14:"doc/manual.sxw";s:4:"584f";s:58:"tests/class.tx_t3deploy_tests_cacheController_testcase.php";s:4:"c182";s:61:"tests/class.tx_t3deploy_tests_databaseController_testcase.php";s:4:"1b51";s:51:"tests/class.tx_t3deploy_tests_dispatch_testcase.php";s:4:"9bd1";s:43:"tests/fixtures/testextension/ext_tables.sql";s:4:"47eb";}',
	'suggests' => array(
	),
);

?>