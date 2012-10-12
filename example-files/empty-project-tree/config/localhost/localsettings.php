<?php
$typo_db_username = 'db_user';
$typo_db_password = 'domain';
$typo_db_host = 'localhost';
$typo_db = 'domain';
$target_apache_user_group = 'www-data';

$TYPO3_CONF_VARS['SYS']['sitename'] = 'Domain [LOCAL]';
$TYPO3_CONF_VARS['SYS']['forceReturnPath'] = '1';
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

$TYPO3_CONF_VARS['BE']['fileCreateMask'] = '0664';
$TYPO3_CONF_VARS['BE']['folderCreateMask'] = '2775';
$TYPO3_CONF_VARS['BE']['createGroup'] = '$target_apache_user_group';

// Disable caching where possible
$TYPO3_CONF_VARS['EXT']['extCache'] = '0';

?>