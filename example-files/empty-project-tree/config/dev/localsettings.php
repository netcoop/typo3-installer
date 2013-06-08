<?php
$typo_db_username = 'db_user';
$typo_db_password = '***';
$typo_db_host = 'db.dev.web';
$typo_db = 'domain_com';
$target_apache_user_group = 'www-data';

//$TYPO3_CONF_VARS['SYS']['curlProxyServer'] = 'http://***:3128/';
//$TYPO3_CONF_VARS['SYS']['curlUse'] = '1';
$TYPO3_CONF_VARS['SYS']['sitename'] = 'Domain.com [DEV]';
$TYPO3_CONF_VARS['SYS']['forceReturnPath'] = '0';
$TYPO3_CONF_VARS['SYS']['enableDeprecationLog'] = 'file';
$TYPO3_CONF_VARS['SYS']['sqlDebug'] = '1';
$TYPO3_CONF_VARS['SYS']['displayErrors'] = '1';
$TYPO3_CONF_VARS['SYS']['devIPmask'] = '*';
$TYPO3_CONF_VARS['SYS']['errorHandler'] = 't3lib_error_ErrorHandler';
$TYPO3_CONF_VARS['SYS']['errorHandlerErrors'] = E_ALL ^ E_NOTICE;
$TYPO3_CONF_VARS['SYS']['exceptionalErrors'] = E_ALL ^ E_NOTICE ^ E_WARNING ^ E_USER_ERROR ^ E_USER_NOTICE ^ E_USER_WARNING;
$TYPO3_CONF_VARS['SYS']['exceptionHandler'] = 't3lib_error_DebugExceptionHandler';
$TYPO3_CONF_VARS['SYS']['systemLogLevel'] = 0;
$TYPO3_CONF_VARS['SYS']['systemLog'] = 'error_log,,2;syslog,LOCAL0,,3;file,/Users/Shared/log/typo3_local.log';
$TYPO3_CONF_VARS['SYS']['enable_DLOG'] = 1;

//$TYPO3_CONF_VARS['BE']['lockSSL'] = '2';

$TYPO3_CONF_VARS['BE']['fileCreateMask'] = '0660';
$TYPO3_CONF_VARS['BE']['folderCreateMask'] = '2770';
$TYPO3_CONF_VARS['BE']['createGroup'] = $target_apache_user_group;

?>