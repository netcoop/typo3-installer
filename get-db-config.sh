#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo "Usage: $scriptname"
	echo "	-b <dir>  : specify project base <dir> ($project_base_dir)"
	echo "	-c <file> : specify config <file> ($target_config_file)"
	echo "	-w <dirname> : specify name of www directorybackup <dirname> ($www_dir)"
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
	if [ ! -e $target_config_file ]; then
		echo "$scriptname: ERROR: No configuration file found in $target_config_file. Aborting"
		exit 1
	fi
	echo "$scriptname: Retrieving settings from $target_config_file"

	export target_username=`grep 'typo_db_username' $target_config_file | sed -e 's/^.*typo_db_username *= *\(.*\).*;$/\1/' | tr -d "'"`
	export target_password=`grep 'typo_db_password' $target_config_file | sed -e 's/^.*typo_db_password *= *\(.*\).*;$/\1/' | tr -d "'"`
	export target_host_with_port=`grep 'typo_db_host'         $target_config_file | sed -e 's/^.*typo_db_host *= *\(.*\).*;$/\1/'     | tr -d "'"`
	host_port=(`echo $target_host_with_port | tr ":" " "`)
	export target_host=`echo ${host_port[0]}`
	export target_port=`echo ${host_port[1]}`
	export target_database=`grep 'typo_db '         $target_config_file | sed -e 's/^.*typo_db *= *\(.*\).*;$/\1/'          | tr -d "'"`
	export target_apache_user_group=`grep '^ *\$target_apache_user_group' $target_config_file | sed -e 's/^ *\$target_apache_user_group *= *\(.*\).*;$/\1/' | tr -d "'"`
}

scriptname=$(basename $0)
set_project_dir

args=`getopt c:b:w: $*`
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
		-c)
			target_config_file="$2";
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

if [ -z $target_config_file ] ; then
	target_config_file=${project_base_dir}/${www_dir}/local/config/localsettings.php
fi

get_db_config

if [ -z "$echo_config" ]; then
	export echo_config=1
	echo "$scriptname: target_username:          $target_username"
	# DISABLED FOR SECURITY
	#echo "$scriptname: target_password:          $target_password"
	echo "$scriptname: target_host:              $target_host"
	echo "$scriptname: target_port:              $target_port"
	echo "$scriptname: target_database:          $target_database"
	echo "$scriptname: target_apache_user_group: $target_apache_user_group"
fi
