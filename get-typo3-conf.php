<?php

/**
 * Return specified values from TYPO3 configuration files for use in shell scripts
 *
 * @param1 name of webroot dir
 * @param2 name of PHP variable to return, or array key in TYPO3_CONF_VARS if @param3 is set
 * @param3 sub-array key in TYPO3_CONF_VARS
 */

// If not run from the command line, then exit silently
if (php_sapi_name() != 'cli') {
	die();
}

global $TYPO3_CONF_VARS;

if (isset($argv[1])) {
	if (is_dir($argv[1])) {
		$webroot = rtrim($argv[1], '/\ ');
		define('PATH_site', $webroot . '/');

		if (file_exists($webroot . '/typo3conf/LocalConfiguration.php')) {
			// TYPO3 version >= 6.0
			$GLOBALS['TYPO3_CONF_VARS'] = require($webroot . '/typo3conf/LocalConfiguration.php');
			@include($webroot . '/typo3conf/AdditionalConfiguration.php');
		} elseif (file_exists($webroot . '/typo3conf/localconf.php')) {
			// TYPO3 version <= 4.7.x
			require($webroot . '/typo3conf/localconf.php');
		}

		// If arguments 2 and 3 are set, return value from TYPO3_CONF_VARS array
		if (isset($argv[3])) {
			if (isset($GLOBALS['TYPO3_CONF_VARS'][$argv[2]][$argv[3]])) {
				echo $GLOBALS['TYPO3_CONF_VARS'][$argv[2]][$argv[3]];
			}
		// if only argument 2 is set, return value from the variable with that name
		} elseif (isset($argv[2])) {
			echo $$argv[2];
		}
	}
}
?>