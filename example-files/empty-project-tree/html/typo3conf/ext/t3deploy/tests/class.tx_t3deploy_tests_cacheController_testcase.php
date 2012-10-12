<?php
/***************************************************************
*  Copyright notice
*
*  (c) 2009 AOE media GmbH <dev@aoemedia.de>
*  All rights reserved
*
*  This copyright notice MUST APPEAR in all copies of the script!
***************************************************************/

require_once PATH_tx_t3deploy . 'classes/class.tx_t3deploy_cacheController.php';

/**
 * Testcase for class tx_t3deploy_databaseController.
 *
 * @package t3deploy
 * @author Oliver Hader <oliver.hader@aoemedia.de>
 */
class tx_t3deploy_tests_cacheController_testcase extends tx_phpunit_testcase {
	
	/**
	 * @var tx_t3deploy_cacheController
	 */
	private $controller;

	/**
	 * Sets up the test cases.
	 *
	 * @return void
	 */
	public function setUp() {

		$this->controller = new tx_t3deploy_cacheController();
		
	}

	/**
	 * Cleans up the test cases.
	 *
	 * @return void
	 */
	public function tearDown() {
		
		unset($this->controller);
	}

	/**
	 * Tests whether the TCEmain is loaded
	 *
	 * @test
	 * @return void
	 */
	public function setterSetsTcemain() {
		
		$TCE = $this->controller->getTCE();
		
		$this->assertInstanceOf(t3lib_TCEmain, $TCE);
	}
	
	/*
	 * TESTS
	 * - BE Users has the rights to clear the cache
	 * - Give the rights?
	 * - Clear Cache, cleared the cache
	 * 
	 */
}