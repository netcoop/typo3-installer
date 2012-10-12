<?php
/***************************************************************
*  Copyright notice
*
*  (c) 2012 Tryweb V.O.F <support@tryweb.nl>
*  All rights reserved
*
*  This copyright notice MUST APPEAR in all copies of the script!
***************************************************************/

/**
 * Controller that handles database actions of the t3deploy process inside TYPO3.
 *
 * @package t3deploy
 * @author Sebastiaan van Parijs <svparijs@tryweb.nl>
 *
 */
class tx_t3deploy_cacheController {

	/**
	 * object <t3lib_TCEmain>
	 */
	protected $TCE;
	
	/**
	 * array
	 */
	protected $help;


	/**
	 * Creates this object.
	 */
	public function __construct() {
		$this->setHelp();	
		$this->setTCE();
        // this seems to initalized a BE
        $this->TCE->start(Array(),Array());
		// We need a admin user to clear the full cache
		$this->TCE->admin = TRUE;
	}
	
	/**
	 * Updates the database structure.
	 *
	 * @param array $arguments Optional arguemtns passed to this action
	 * @return void
	 */
	public function clearCacheAction(array $arguments){
		
		// Clear Cache option storage
		$options = array();
		// Arguments have 1 row by default
		if (count($arguments) > 1) {
			foreach( $arguments as $argument => $val){
				switch($argument){
					case (substr($argument, 0, 5) == '--pid'):
						$options[] = substr($argument, 5, strlen($argument));
					break;
					case '-t':
					case '--temp_CACHED':
						$options[] = 'temp_CACHED';
					break;
					case '-p':
					case '--pages':
						$options[] = 'pages';
					break;
					case '-a':
					case '--all':
						$options[] = 'all';
					break;
					case '-h':
					case '--help':
					#default:	
						$help = $this->getHelp();
						
						// The help information output
						foreach($help as $option => $description){
							$result .= ($result ? PHP_EOL : ''). $option .'		'. $description;
						}
					break;
				}
			}
		} else {
			$options[] = 'all';		
		}
		
		foreach($options as $option) {
			$this->TCE->clear_cacheCmd($option);
			$result .= ($result ? PHP_EOL : '') .'T3Deploy: Clear Cache with option: '. $option;
		}
		
		return $result;
	}
	
	/**
	 * Sets the TCEmain object
	 * 
	 * @return void
	 */
	private function setTCE(){
		$this->TCE = t3lib_div::makeInstance('t3lib_TCEmain');
	}
	
	/**
	 *	Gets the TCEmain object
	 * 
	 * @return t3lib_TCEmain $TCE
	 */
	public function getTCE(){
		return $this->TCE;
	}
	
	
	/**
	 * Sets the Help array
	 * 
	 * @return void
	 */
	public function setHelp(){
		
		$help = array( 'Help' => '',
						'Options:' => '',
						'--pid[int]	' => ': Clear cache of a specific page!, (Example --pid123  )',
						'--temp_CACHED, -t' => ': Removes cache Files!',
						'--pages, -p	' => ': Clear cache for ALL pages!',
						'--all, -a	' => ': [Default] Clear cache for ALL tables & removes cache files!');
		
		$this->help = $help;
	}
	
	/**
	 *	Gets the Help array
	 * @return array help
	 */
	public function getHelp(){
		return $this->help;
	}
}
