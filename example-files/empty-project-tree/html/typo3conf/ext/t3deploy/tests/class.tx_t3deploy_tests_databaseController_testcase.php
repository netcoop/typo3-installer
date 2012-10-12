<?php
/***************************************************************
*  Copyright notice
*
*  (c) 2009 AOE media GmbH <dev@aoemedia.de>
*  All rights reserved
*
*  This copyright notice MUST APPEAR in all copies of the script!
***************************************************************/

require_once PATH_tx_t3deploy . 'classes/class.tx_t3deploy_databaseController.php';

/**
 * Testcase for class tx_t3deploy_databaseController.
 *
 * @package t3deploy
 * @author Oliver Hader <oliver.hader@aoemedia.de>
 */
class tx_t3deploy_tests_databaseController_testcase extends tx_phpunit_database_testcase {
	/**
	 * @var tx_t3deploy_databaseController
	 */
	private $controller;

	/**
	 * @var array
	 */
	private $testLoadedExtensions;

	/**
	 * @var string
	 */
	private $testExtensionsName;

	/**
	 * Sets up the test cases.
	 *
	 * @return void
	 */
	public function setUp() {
		$this->createDatabase();
		$this->useTestDatabase();

		$this->testExtensionsName = uniqid('testextension');
		$this->testLoadedExtensions = array(
			$this->testExtensionsName = array(
				'type' => 'L',
				'ext_tables.sql' => PATH_tx_t3deploy . 'tests/fixtures/testextension/ext_tables.sql',
			),
		);

		$this->controller = new tx_t3deploy_databaseController();
	}

	/**
	 * Cleans up the test cases.
	 *
	 * @return void
	 */
	public function tearDown() {
		$this->dropDatabase();

		unset($this->testExtensionsName);
		unset($this->testLoadedExtensions);
		unset($this->controller);
	}

	/**
	 * Tests whether the updateStructure action just reports the changes
	 *
	 * @test
	 * @return void
	 */
	public function doesUpdateStructureActionReportChanges() {
		$this->importStdDB();
		$arguments = array(
			'--verbose' => '',
		);

		$this->controller->setLoadedExtensions($this->testLoadedExtensions);
		$result = $this->controller->updateStructureAction($arguments);

		// Assert that nothing has been created, this is just for reporting:
		$tables = $GLOBALS['TYPO3_DB']->admin_get_tables();
		$pagesFields = $GLOBALS['TYPO3_DB']->admin_get_fields('pages');
		$this->assertFalse(isset($tables['tx_testextension']));
		$this->assertNotEquals('varchar(33)', strtolower($pagesFields['alias']['Type']));

		// Assert that changes are reported:
		$this->assertContains('ALTER TABLE pages ADD tx_testextension_field', $result);
		$this->assertContains('ALTER TABLE pages CHANGE alias alias varchar(33)', $result);
		$this->assertContains('CREATE TABLE tx_testextension', $result);
	}

	/**
	 * Test whether the updateStructure action just executes the changes.
	 *
	 * @test
	 * @return void
	 */
	public function doesUpdateStructureActionExecuteChanges() {
		$this->importStdDB();

		$arguments = array(
			'--execute' => '',
		);

		$this->controller->setLoadedExtensions($this->testLoadedExtensions);
		$result = $this->controller->updateStructureAction($arguments);

		// Assert that tables have been created:
		$tables = $GLOBALS['TYPO3_DB']->admin_get_tables();
		$pagesFields = $GLOBALS['TYPO3_DB']->admin_get_fields('pages');
		$this->assertTrue(isset($tables['tx_testextension']));
		$this->assertTrue(isset($pagesFields['tx_testextension_field']));
		$this->assertEquals('varchar(33)', strtolower($pagesFields['alias']['Type']));

		// Assert that nothing is reported we just want to execute:
		$this->assertEquals('', $result);
	}
}