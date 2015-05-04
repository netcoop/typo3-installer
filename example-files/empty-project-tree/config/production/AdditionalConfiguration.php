<?php
$target_apache_user_group = 'www-data';
$additionalConfiguration = array(
	'BE' => array(
		'createGroup' => $target_apache_user_group,
		'fileCreateMask' => '0664',
		'folderCreateMask' => '2775',
	),
	'DB' => array(
		'database' => '',
		'extTablesDefinitionScript' => 'extTables.php',
		'host' => 'localhost',
		'password' => '',
		'socket' => '',
		'username' => '',
	),
);

//@require_once('html/typo3/sysext/core/Classes/Utility/GeneralUtility.php');
//$GLOBALS['TYPO3_CONF_VARS'] = TYPO3\CMS\Core\Utility\GeneralUtility::array_merge_recursive_overrule($GLOBALS['TYPO3_CONF_VARS'], $additionalConfiguration);
if (is_array($GLOBALS['TYPO3_CONF_VARS'])) {
	$GLOBALS['TYPO3_CONF_VARS'] = array_replace_recursive($GLOBALS['TYPO3_CONF_VARS'], $additionalConfiguration);
} else {
	$GLOBALS['TYPO3_CONF_VARS'] = $additionalConfiguration;
}

?>
