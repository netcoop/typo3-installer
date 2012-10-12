<?php
/***************************************************************
*  Copyright notice
*
*  (c) 2009 AOE media GmbH <dev@aoemedia.de>
*  All rights reserved
*
*  This copyright notice MUST APPEAR in all copies of the script!
***************************************************************/

require_once PATH_tx_t3deploy . 'classes/class.tx_t3deploy_dispatch.php';

/**
 * Testcase for class tx_t3deploy_dispatch.
 *
 * @package t3deploy
 * @author Oliver Hader <oliver.hader@aoemedia.de>
 */
class tx_t3deploy_tests_dispatch_testcase extends tx_phpunit_testcase {
	const ClassPrefix = 'tx_t3deploy_';
	const ClassSuffix = 'Controller';

	/**
	 * @var string
	 */
	private $testClassName;

	/**
	 * @var tx_t3deploy_dispatch
	 */
	private $dispatch;

	/**
	 * Sets up the test cases.
	 *
	 * @return void
	 */
	public function setUp() {
		$_SERVER['argv'] = array();

		$this->testClassName = uniqid('testClassName');
		eval('class ' . self::ClassPrefix . $this->testClassName . self::ClassSuffix . ' {}');

		$this->dispatch = new tx_t3deploy_dispatch();
	}

	/**
	 * Cleans up the test cases.
	 *
	 * @return void
	 */
	public function tearDown() {
		unset($this->dispatch);
	}

	/**
	 * Tests whether a controller is correctly dispatched
	 *
	 * @test
	 */
	public function isControllerActionCorrectlyDispatched() {
		$cliArguments = array(
			'_DEFAULT' => array(
				't3deploy',
				$this->testClassName,
				'test'
			)
		);

		$testMock = $this->getMock($this->testClassName, array('testAction'));
		$testMock->expects($this->once())->method('testAction')->will($this->returnValue($this->testClassName));

		$this->dispatch->setCliArguments($cliArguments);
		$this->dispatch->setClassInstance(
			self::ClassPrefix . $this->testClassName . self::ClassSuffix,
			$testMock
		);
		$result = $this->dispatch->dispatch();

		$this->assertEquals($this->testClassName, $result);
	}
}