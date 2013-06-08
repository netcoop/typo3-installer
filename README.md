typo3-installer
===============

Automatic deployment tool for TYPO3 v4/v6

This documentation is far from complete, but it should get you started!


Requirements:
===============

- a development machine running Linux or Mac OSX (it might work on Windows in a cygwin or similar environment, but never tested, don't count on it)
- ant (http://ant.apache.org/) on ubuntu or debian: apt-get install ant
- ant jsch (http://www.jcraft.com/jsch/) I installed it manually, see dir example-files/ant, but maybe apt-get install libjsch-java will do
	Manual install, on Linux or MAC OSX:
	Copy the files ant-jsch-x.x.x.jar and jsch-x.x.x.jar from example-files/ant to ~/.ant/lib/ (create the directories if they don't exist)
- git (http://git-scm.com/) apt-get install git
- ssh with public/private key authentication for connecting to the servers you need to connect to (FTP is not supported)
- rsync (http://rsync.samba.org/) apt-get install rsync, required on your development machine and/or your Jenkins server, and all servers you want to deploy to

- TYPO3 v4.5 up to v6.1.x
- included in this package: extended version of TYPO3 extension t3deploy

Optional: a local LAMP-stack for development (I prefer to work that way, but you may have different habits or requirements)


How to use the TYPO3-installer?
===============

- Create a project directory for your project on your development machine:
```
mkdir <project-dir>
cd <project-dir>
```
- Initialize git:
```
git init
```
- Include the TYPO3-installer as a git submodule:
```
git submodule add https://github.com/netcoop/typo3-installer.git installer
```
- Create the required directory structure for the project:

cp -a installer/example-files/empty-project-tree/. .

- => If you don't already have this, create a directory src OUTSIDE OF THIS PROJECT DIRECTORY but at the same level, containing the TYPO3 sources (core)
- Inside the sources directory, create a symlink with the major version number to the latest version of that branch, e.g.:
```
mkdir ../src
cd ../src
ln -s typo3_src-4.7.4 typo3_src-4.7
cd <project-dir>
```
- => Create a database and database user for your project

- => Modify the settings in the files under config/localhost to fit your project and system (paths, database credentials, etc.)
- Once that is done, you should be able to get the rest of your local installation ready using this command:
```
./installer/local-install.sh -e localhost
```
- where localhost is the name of this configuration directory you use from the config directory

- Your new empty local development site should now be up-and-running!
- Commit your work, this is the starting point for all changes to this project:
```
git commit -am "Initial commit"
```

Changing the TYPO3 main version
===============

- By default the installer now uses TYPO3 4.7. To change this to 4.6 or 4.5, just change the well known setting in datasets/0.0.0/files/typo3conf/localconf.php
```
$TYPO3_CONF_VARS['SYS']['compat_version'] = '4.7';
```
- and move the appropriate empty database file into the 0.0.0 dataset directory:
```
mv datasets/0.0.0/base_4.7.x.sql datasets/
mv datasets/base_4.5.x.sql datasets/0.0.0/
```
- Once you have your local installation already running, then also adjust [compat_version] setting in the active localconf.php in html/typo3conf/localconf.php
- Do this by hand, not by using the install tool (because the comments added by the install tool currently break the create-symlinks.sh script).


Set up SSH properties
===============

- Now create a file in your local home directory for being able to use the public/private keys with Ant SSH and SCP
- I'm not that happy about the passphrase file, but I don't know a better way, due to limitations of ant's ssh implementation
```
echo -e "ssh.passphrase=<your-ssh-key-passphrase>\nssh.keyfile=\${user.home}/.ssh/id_rsa" > ~/.ssh.properties
chmod 600 ~/.ssh.properties
```
- Warning: this file should never be included in your project and/or pushed to a remote repository, as it contains your SSH passphrase!

- If you use different SSH-keys for different environments, then you can choose to specify a different ssh.file.properties in the environment.properties.
- This will override the file specified in project.properties (which will be used for all environments)


Hierarchy of properties files
===============

- The ant deployment script (build.xml) uses 4 files with file extension '.properties' to read the deployment settings from:

1. version.properties		(contains only version number and should also be readable by shell scripts)
2. environment.properties	(in config/<target-environment>/, this contains the settings for this environment)
3. project.properties		(in project root, contains project defaults for all environment)
4. ssh.file.properties		(in user home-dir or other relatively safe location, contains passphrase and location of private key file)

- They are read in this sequence. Once a setting is set, it can not be changed (Ant does not override variables like you're used to in PHP etc.) Therefore, the first file has the highest priority. Specify the default settings for all environments in project.properties, then you can "override" them in environment.properties.

- version.properties should only be used for setting the version number. Increase it after every incremental deployment to an environment where the live-data is preserved.


Deploy to target environments
===============

- Adjust the configuration for each target environment under config/***
- You can also freely add new target environments, you can also change the names of the targets as you wish.

- To perform a deployment, do:
```
ant deploy -Denvironment=test
```
- where 'test' is the name of the target environment in the config directory.
- This will transfer the necessary components (installer scripts, dataset if required and versioned files) using rsync, and run a number of scripts to apply the changes to the target environment. File transfer using rsync ensures very fast deployment once a site has already been deployed before (only changes need to be transferred).

- For advanced users: you can also override other Ant variables by specifying them on the command line.


Creating a dataset
===============

Currently, you create a dataset by first creating a backup, and then create a dataset from that specific backup
This procedure is likely to change!


Using datasets
===============

If you specify a dataset by setting e.g. 'deploy.dataset = 0.0.2.dev-data', then the deployment script will drop the existing database and deploy your project
using the specified dataset. This is useful for development and test-deployments, maybe sometimes for acceptation environments, but never for production,
unless you really want to deploy a new database and fileset and throw away all data on the production environment (normally you would only do this for the
initial deployment of a new project, never for existing sites).

There are 2 kinds of datasets:

- versioned datasets (included in git) in directory datasets. These can be deployed automatically on every deployment.
- local datasets (not in git) in directory datasetslocal. Use this when a dataset (e.g. from an existing project) is too big to practically stored in git. Make sure you copy this dataset to each server where you want to use it.

Refresh your local installation
===============

./installer/replace-local-database.sh [<data-set>]


Directory structure for a project:
===============

TODO: explanation of what is what

- backup
- config
	- localhost
	- test
	- acceptation
	- production
- datasets
	- 0.0.0
		- files
			- fileadmin
			1. (....)
		1. base_4.5.x.sql
	1. base_4.6.x.sql
	2. base_4.7.x.sql
	3. cli_users.sql
	4. cursor.sql
	5. tx_devlog.sql
- datasetslocal
- deltas
	- 0.0.1
		- files
			- fileadmin
			1. (....)
		1. updates.sql
		2. updates.sh
- html
	- local
		- config
		- log
		1. .htaccess
	- typo3conf
		- ext
			- t3deploy
- log
- worktemp
- .git
1. build.xml
2. project.properties
3. version.properties
4. .gitignore
5. .rsync-exclude


Using deltas
===============

The directory deltas contains subdirectories with version numbers like 0.0.1 or 1.12.3.
Each version can contain 3 types of deltas:
- updates.sql		queries to be performed on deployment
- files (directory)	all contents will be copied onto the existing site root on deployment
- updates.sh		an executable shell script which will be run on deployment

On deployment, the script apply-deltas.sh checks the current version of the data on the target environment and will apply all deltas with a version number higher than the current version.

Database modifications specified in TCA will be automatically applied by the extension t3deploy before the deltas are applied.
Tables or fields that are removed from TCA will NOT be deleted automatically, as this could break earlier sql updates. Do this manually, and create a new dataset immediately after to use as a base for further development and testing.

