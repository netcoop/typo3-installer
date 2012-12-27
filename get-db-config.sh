#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo "Usage: $scriptname"
	echo "	-b <dir>  : specify project base <dir> ($project_base_dir)"
	echo "	-w <dirname> : specify name of www directory <dirname> ($www_dir)"
}

set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

get_db_config()
{
	if [ -e ${project_base_dir}/${www_dir}/typo3conf/LocalConfiguration.php ]; then
		# TYPO3 version >= 6
		echo "$scriptname: Retrieving settings from typo3conf/LocalConfiguration.php (TYPO3 version >= 6.0)"
		export target_username=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} DB username`
		export target_password=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} DB password`
		export target_host_with_port=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} DB host`
		export target_database=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} DB database`

	elif [ -e ${project_base_dir}/${www_dir}/typo3conf/localconf.php ]; then
		# TYPO3 version <= 4.7.x
		echo "$scriptname: Retrieving settings from typo3conf/localconf.php (TYPO3 version <= 4.7.x)"
		export target_username=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} typo_db_username`
		export target_password=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} typo_db_password`
		export target_host_with_port=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} typo_db_host`
		export target_database=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} typo_db`

	else
		echo "$scriptname: ERROR: No TYPO3 local configuration file found in ${www_dir}/typo3conf. Aborting"
		exit 1
	fi

	export target_apache_user_group=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} BE createGroup`

	host_port=(`echo $target_host_with_port | tr ":" " "`)
	export target_host=`echo ${host_port[0]}`
	export target_port=`echo ${host_port[1]}`
}

scriptname=$(basename $0)
scriptdir=$(dirname $0)
# Set default project_base_dir (can be overruled with script parameter -b)
set_project_dir

# Set default www_dir name (can be overruled with script parameter -w)
www_dir=html

args=`getopt b:w: $*`
# you should not use `getopt abo: "$@"` since that would parse
# the arguments differently from what the set command below does.
if [ $? != 0 ]
then
	usage
	exit 2
fi
set -- $args
# You cannot use the set command with a backquoted getopt directly,
# since the exit code from getopt would be shadowed by those of set,
# which is zero by definition.
for i
do
	case "$i"
	in
		-b)
			project_base_dir="$2";
			shift;
			shift;;
		-w)
			www_dir="$2";
			shift;
			shift;;
		--)
			shift;
			break;;
	esac
done

get_db_config

if [ -z "$echo_config" ]; then
	export echo_config=1
	echo "$scriptname: target_username:          $target_username"
	# DISABLED FOR SECURITY
	echo "$scriptname: target_password:          $target_password"
	echo "$scriptname: target_host:              $target_host"
	echo "$scriptname: target_port:              $target_port"
	echo "$scriptname: target_database:          $target_database"
	echo "$scriptname: target_apache_user_group: $target_apache_user_group"
fi
