<?php
$typo_db_username = 'db_user';
$typo_db_password = '***';
$typo_db_host = 'db-server.domain.com';
$typo_db = 'domain_com';
$target_apache_user_group = 'www-data';

$TYPO3_CONF_VARS['SYS']['sqlDebug'] = '0';
$TYPO3_CONF_VARS['SYS']['displayErrors'] = '0';
$TYPO3_CONF_VARS['SYS']['devIPmask'] = '';
$TYPO3_CONF_VARS['SYS']['errorHandler'] = '';
$TYPO3_CONF_VARS['SYS']['exceptionHandler'] = '';
$TYPO3_CONF_VARS['SYS']['systemLog'] = '';
$TYPO3_CONF_VARS['SYS']['enable_DLOG'] = 0;
$TYPO3_CONF_VARS['SYS']['forceReturnPath'] = '1';
$TYPO3_CONF_VARS['SYS']['enableDeprecationLog'] = '0';
$TYPO3_CONF_VARS['BE']['fileCreateMask'] = '0660';
$TYPO3_CONF_VARS['BE']['folderCreateMask'] = '2770';
$TYPO3_CONF_VARS['BE']['createGroup'] = '$target_apache_user_group';

// List of extension that are automatically de-installed in this environment:
$devOnlyExtensions = array('kickstarter', 'devlog', 'phpunit', 'extdeveval', 'extension_builder');
foreach ($devOnlyExtensions as $removeFromList) {
	$TYPO3_CONF_VARS['EXT']['extList'] = str_replace(','.$removeFromList, '', $TYPO3_CONF_VARS['EXT']['extList']);
	$TYPO3_CONF_VARS['EXT']['extList_FE'] = str_replace(','.$removeFromList, '', $TYPO3_CONF_VARS['EXT']['extList_FE']);
}
?>