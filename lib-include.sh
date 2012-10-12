#!/bin/bash
binDir=/usr/bin/

##
## echo with scriptname prepended
##
lib_echo()
{
	echo "$scriptname: $1"
}

##
## echo with scriptname and 'ERROR' prepended
## additionally exits the script with error code 1
##
lib_error()
{
	echo "$scriptname: ERROR: $1"
	exit 1;
}

##
## set the value for $project_base_dir
##
lib_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}


##
##
##
lib_get_db_config()
{
	config_file=$project_base_dir/html/local/config/localsettings.php
	if [ ! -e $config_file ]; then
		lib_error "Configuration file $config_file not found. Aborting"
	fi

	export target_username=`grep 'typo_db_username' $target_config_file | sed -e 's/^.*typo_db_username *= *\(.*\).*;$/\1/' | tr -d "'"`
	export target_password=`grep 'typo_db_password' $target_config_file | sed -e 's/^.*typo_db_password *= *\(.*\).*;$/\1/' | tr -d "'"`
	export target_host_with_port=`grep 'typo_db_host'         $target_config_file | sed -e 's/^.*typo_db_host *= *\(.*\).*;$/\1/'     | tr -d "'"`
	host_port=(`echo $target_host_with_port | tr ":" " "`)
	export target_host=`echo ${host_port[0]}`
	export target_port=`echo ${host_port[1]}`
	export target_database=`grep 'typo_db '         $target_config_file | sed -e 's/^.*typo_db *= *\(.*\).*;$/\1/'          | tr -d "'"`
	export target_apache_user_group=`grep '^ *\$target_apache_user_group' $target_config_file | sed -e 's/^ *\$target_apache_user_group *= *\(.*\).*;$/\1/' | tr -d "'"`
}


##
##
##
mysql_import()
{
	lib_echo "Import $1 into $target_database..."
	mysql --host=$target_host --port=$target_port -u $target_username -p"$target_password" $target_database --default-character-set=utf8 < $1
	if [ "$?" -ne 0 ]; then lib_error "Failed to import $1."; exit 1; fi
}

cd "$(dirname "$0")"
scriptdir=`pwd`
lib_project_dir
initial_version="0.0.0"
data_version_file=$project_base_dir/.data.version
deltas_path=$project_base_dir/$deltas_dir

cli_user_file=$project_base_dir/datasets/cli_users.sql
cursor_file=$project_base_dir/datasets/cursor.sql

#echo_error "Dit gaat goed fout!"