<?php
/***************************************************************
*  Copyright notice
*
*  (c) 2009 AOE media GmbH <dev@aoemedia.de>
*  All rights reserved
*
*  This copyright notice MUST APPEAR in all copies of the script!
***************************************************************/

require_once PATH_t3lib . 'class.t3lib_cli.php';

/**
 * General CLI dispatcher for the t3deploy extension.
 *
 * @package t3deploy
 * @author Oliver Hader <oliver.hader@aoemedia.de>
 */
class tx_t3deploy_dispatch extends t3lib_cli {
	const ExtKey = 't3deploy';
	const Mask_ClassName = 'tx_t3deploy_%sController';
	const Mask_ClassFile = 'classes/class.tx_t3deploy_%sController.php';
	const Mask_Action = '%sAction';

	/**
	 * @var array
	 */
	protected $classInstances = array();

	/**
	 * Creates this object.
	 */
	public function __construct() {
		parent::__construct();
		$this->cli_help = array_merge($this->cli_help, array(
			'name' => 'tx_t3deploy_dispatch',
			'synopsis' => self::ExtKey . ' controller action ###OPTIONS###',
			'description' => '',
			'examples' => 'typo3/cli_dispatch.phpsh ' . self::ExtKey . ' database updateStructure',
			'author' => '(c) 2010 AOE media GmbH <dev@aoemedia.de>',
		));
	}

	/**
	 * Sets the CLI arguments.
	 *
	 * @param array $arguments
	 * @return void
	 */
	public function setCliArguments(array $arguments) {
		$this->cli_args = $arguments;
	}

	/**
	 * Gets or generates an instance of the given class name.
	 *
	 * @param string $className
	 * @return object
	 */
	public function getClassInstance($className) {
		if (!isset($this->classInstances[$className])) {
			$this->classInstances[$className] = t3lib_div::makeInstance($className);
		}
		return $this->classInstances[$className];
	}

	/**
	 * Sets an instance for the given class name.
	 *
	 * @param string $className
	 * @param object $classInstance
	 * @return void
	 */
	public function setClassInstance($className, $classInstance) {
		$this->classInstances[$className] = $classInstance;
	}

	/**
	 * Dispatches the requested actions to the accordant controller.
	 *
	 * @return void
	 */
	public function dispatch() {
		$controller = (string)$this->cli_args['_DEFAULT'][1];
		$action = (string)$this->cli_args['_DEFAULT'][2];

		if (!$controller || !$action) {
			throw new Exception('The CLI process must be called with a controller and action name.');
		}

		$className = sprintf(self::Mask_ClassName, $controller);
		$classFile = sprintf(self::Mask_ClassFile, $controller);
		$actionName = sprintf(self::Mask_Action, $action);

		if (!class_exists($className)) {
			t3lib_div::requireOnce(PATH_tx_t3deploy . $classFile);
		}

		$instance = $this->getClassInstance($className);

		if (!is_callable(array($instance, $actionName))) {
			throw new Exception('The action ' . $action . ' is not implemented in controller ' . $controller);
		}

		$result = call_user_func_array(
			array($instance, $actionName),
			array($this->cli_args)
		);

		return $result;
	}
}
