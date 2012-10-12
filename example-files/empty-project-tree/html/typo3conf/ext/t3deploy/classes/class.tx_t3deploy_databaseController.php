<?php
/***************************************************************
*  Copyright notice
*
*  (c) 2009 AOE media GmbH <dev@aoemedia.de>
*  All rights reserved
*
*  This copyright notice MUST APPEAR in all copies of the script!
***************************************************************/

t3lib_div::requireOnce(PATH_t3lib . 'class.t3lib_install.php');

/**
 * Controller that handles database actions of the t3deploy process inside TYPO3.
 *
 * @package t3deploy
 * @author Oliver Hader <oliver.hader@aoemedia.de>
 *
 */
class tx_t3deploy_databaseController {
	/*
	 * List of all possible update types:
	 *	+ add, change, drop, create_table, change_table, drop_table, clear_table
	 * List of all sensible update types:
	 *	+ add, change, create_table, change_table
	 */
	const UpdateTypes_List = 'add,change,create_table,change_table';
	const RemoveTypes_list = 'drop,drop_table,clear_table';

	/**
	 * @var t3lib_install_Sql
	 */
	protected $install;

	/**
	 * @var array
	 */
	protected $loadedExtensions;

	/**
	 * @var array
	 */
	protected $consideredTypes;

	/**
	 * Creates this object.
	 */
	public function __construct() {
		if (t3lib_div::compat_version('4.6')) {
			$this->install = t3lib_div::makeInstance('t3lib_install_Sql');
		} else {
			$this->install = t3lib_div::makeInstance('t3lib_install');
		}
		$this->setLoadedExtensions($GLOBALS['TYPO3_LOADED_EXT']);
		$this->setConsideredTypes($this->getUpdateTypes());
	}

	/**
	 * Sets information concerning all loaded TYPO3 extensions.
	 *
	 * @param array $loadedExtensions
	 * @return void
	 */
	public function setLoadedExtensions(array $loadedExtensions) {
		$this->loadedExtensions = $loadedExtensions;
	}

	/**
	 * Sets the types condirered to be executed (updates and/or removal).
	 *
	 * @param array $consideredTypes
	 * @return void
	 * @see updateStructureAction()
	 */
	public function setConsideredTypes(array $consideredTypes) {
		$this->consideredTypes = $consideredTypes;
	}

	/**
	 * Adds considered types.
	 *
	 * @param array $consideredTypes
	 * @return void
	 * @see updateStructureAction()
	 */
	public function addConsideredTypes(array $consideredTypes) {
		$this->consideredTypes = array_unique(
			array_merge($this->consideredTypes, $consideredTypes)
		);
	}

	/**
	 * Updates the database structure.
	 *
	 * @param array $arguments Optional arguemtns passed to this action
	 * @return string
	 */
	public function updateStructureAction(array $arguments) {
		$isExcuteEnabled = (isset($arguments['--execute']) || isset($arguments['-e']));

		$result = $this->executeUpdateStructure($arguments);

		if ($isExcuteEnabled) {
			$result.= ($result ? PHP_EOL : '') . $this->executeUpdateStructure($arguments);
		}

		return $result;
	}

	/**
	 * Executes the database structure updates.
	 *
	 * @param array $arguments Optional arguemtns passed to this action
	 * @param boolean $allowKeyModifications Whether to allow key modifications
	 * @return string
	 */
	protected function executeUpdateStructure(array $arguments) {
		$result = '';

		$isExcuteEnabled = (isset($arguments['--execute']) || isset($arguments['-e']));
		$isRemovalEnabled = (isset($arguments['--remove']) || isset($arguments['-r']));
		$isVerboseEnabled = (isset($arguments['--verbose']) || isset($arguments['-v']));
		$allowKeyModifications = (isset($arguments['--allowkeymodifications']) || isset($arguments['-k']) || $isRemovalEnabled);
		$database = (isset($arguments['--database']) && $arguments['--database'] ? $arguments['--database'] : TYPO3_db);

		$changes = $this->install->getUpdateSuggestions(
			$this->getStructureDifferencesForUpdate($database, $allowKeyModifications)
		);

		if ($isRemovalEnabled) {
				// Disable the delete prefix, thus tables and fields can be removed directly:
			$this->install->deletedPrefixKey = '';
				// Add types considered for removal:
			$this->addConsideredTypes($this->getRemoveTypes());
				// Merge update suggestions:
			$removals = $this->install->getUpdateSuggestions(
				$this->getStructureDifferencesForRemoval($database, $allowKeyModifications),
				'remove'
			);
			$changes = array_merge($changes, $removals);
		}

		if ($isExcuteEnabled || $isVerboseEnabled) {
			$statements = array();

			// Concatenates all statements:
			foreach ($this->consideredTypes as $consideredType) {
				if (isset($changes[$consideredType]) && is_array($changes[$consideredType])) {
					$statements+= $changes[$consideredType];
				}
			}

			if ($isExcuteEnabled) {
				foreach ($statements as $statement) {
					$GLOBALS['TYPO3_DB']->admin_query($statement);
				}
			}

			if ($isVerboseEnabled) {
				$result = implode(PHP_EOL, $statements);
			}
		}

		return $result;
	}

	/**
	 * Removes key modifications that will cause errors.
	 *
	 * @param array $differences The differneces to be cleaned up
	 * @return array The cleaned differences
	 */
	protected function removeKeyModifications(array $differences) {
		$differences = $this->unsetSubKey($differences, 'extra', 'keys', 'whole_table');
		$differences = $this->unsetSubKey($differences, 'diff', 'keys');

		return $differences;
	}

	/**
	 * Unsets a subkey in a given differences array.
	 *
	 * @param array $differences
	 * @param string $type e.g. extra or diff
	 * @param string $subKey e.g. keys or fields
	 * @param string $exception e.g. whole_table that stops the removal
	 * @return array
	 */
	protected function unsetSubKey(array $differences, $type, $subKey, $exception = '') {
		if (isset($differences[$type])) {
			foreach ($differences[$type] as $table => $information) {
				$isException = ($exception && isset($information[$exception]) && $information[$exception]);
				if (isset($information[$subKey]) && $isException === FALSE) {
					unset($differences[$type][$table][$subKey]);
				}
			}
		}

		return $differences;
	}

	/**
	 * Gets the differences in the database structure by comparing
	 * the current structure with the SQL definitions of all extensions
	 * and the TYPO3 core in t3lib/stddb/tables.sql.
	 *
	 * This method searches for fields/tables to be added/updated.
	 *
	 * @param string $database
	 * @param boolean $allowKeyModifications Whether to allow key modifications
	 * @return array The database statements to update the structure
	 */
	protected function getStructureDifferencesForUpdate($database, $allowKeyModifications = FALSE) {
		$differences = $this->install->getDatabaseExtra(
			$this->getDefinedFieldDefinitions(),
			$this->install->getFieldDefinitions_database($database)
		);

		if (!$allowKeyModifications) {
			$differences = $this->removeKeyModifications($differences);
		}

		return $differences;
	}

	/**
	 * Gets the differences in the database structure by comparing
	 * the current structure with the SQL definitions of all extensions
	 * and the TYPO3 core in t3lib/stddb/tables.sql.
	 *
	 * This method searches for fields/tables to be removed.
	 *
	 * @param string $database
	 * @param boolean $allowKeyModifications Whether to allow key modifications
	 * @return array The database statements to update the structure
	 */
	protected function getStructureDifferencesForRemoval($database, $allowKeyModifications = FALSE) {
		$differences = $this->install->getDatabaseExtra(
			$this->install->getFieldDefinitions_database($database),
			$this->getDefinedFieldDefinitions()
		);

		if (!$allowKeyModifications) {
			$differences = $this->removeKeyModifications($differences);
		}

		return $differences;
	}

	/**
	 * Gets the defined field definitions from the ext_tables.sql files.
	 *
	 * @return array The accordant definitions
	 */
	protected function getDefinedFieldDefinitions() {
		$content = '';
		
		$rawStructureDefinitions = $this->getAllRawStructureDefinitions();
		if (t3lib_div::compat_version('4.6')) {
			// Add caching framework tables if applicable
			$rawStructureDefinitions = array_merge(
											$rawStructureDefinitions,
											$this->install->getStatementArray(t3lib_cache::getDatabaseTableDefinitions(), 1, '^CREATE TABLE ')
										);
		}
		$rawStructureString = implode(chr(10), $rawStructureDefinitions);

		if (method_exists($this->install, 'getFieldDefinitions_fileContent')) {
			$content = $this->install->getFieldDefinitions_fileContent ($rawStructureString);
		} else {
			$content = $this->install->getFieldDefinitions_sqlContent ($rawStructureString);
		}
//echo $content;
		return $content;
	}

	/**
	 * Gets all structure definitions of extensions the TYPO3 Core.
	 *
	 * @return array All structure definitions
	 */
	protected function getAllRawStructureDefinitions() {
		$rawDefinitions = array();
		$rawDefinitions[] = file_get_contents(PATH_t3lib . 'stddb/tables.sql');

		foreach ($this->loadedExtensions as $extension) {
			if (is_array($extension) && $extension['ext_tables.sql'])	{
				$rawDefinitions[] = file_get_contents($extension['ext_tables.sql']);
			}
		}

		return $rawDefinitions;
	}

	/**
	 * Gets the defined update types.
	 *
	 * @return array
	 */
	protected function getUpdateTypes() {
		return t3lib_div::trimExplode(',', self::UpdateTypes_List, TRUE);
	}

	/**
	 * Gets the defined remove types.
	 *
	 * @return array
	 */
	protected function getRemoveTypes() {
		return t3lib_div::trimExplode(',', self::RemoveTypes_list, TRUE);
	}
}
