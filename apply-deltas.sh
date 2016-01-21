#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo "Usage: $scriptname"
	echo "	-i	: Increase DB cursor after applying deltas (for remote installations)"
	echo "	-b <dir>  : specify project base <dir> ($project_base_dir)"
	echo "	-w <dirname> : specify name of www directorybackup <dirname> ($www_dir)"
	echo "	-f		: only copy files"
	echo "	-d		: only import database"
	echo "	-s		: only run update scripts"
}

set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

echo_line()
{
	echo -e "\n ---- $scriptname: "$1
}

mysql_import()
{
	echo "$scriptname:     Import $1 into $target_database..."
	mysql --host=$target_host --port=$target_port -u $target_username -p"$target_password" $target_database --default-character-set=utf8 < $1
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to import $1."; exit 1; fi
}

clear_cache()
{
	if [ -e $www_dir/typo3cms ] ; then
		echo_line "typo3cms - clear all caches:"
		php $www_dir/typo3cms cache:flush --force
		if [ "$?" -ne 0 ]; then echo_line "WARNING: Failed to clear caches using typo3_console script. Installation continues."; fi
	fi
	rm -rf $www_dir/typo3temp/Cache
}

scriptname=$(basename $0)
scriptdir=$(dirname $0)
set_project_dir
increase_db_cursor=0
deltas_dir="deltas"
www_dir="html"

do_files=1
do_database=1
do_scripts=1

args=`getopt ifdsb:w: $*`
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
		-i)
			increase_db_cursor=1
			shift;;
		-f)
			do_files=1;
			do_database=0;
			do_scripts=0;
			shift;;
		-d)
			do_files=0;
			do_database=1;
			do_scripts=0;
			shift;;
		-s)
			do_files=0;
			do_database=0;
			do_scripts=1;
			shift;;
		--)
			shift;
			break;;
	esac
done


########################################################################################################
#		Retrieving DB Version (Set or Unset) And applying version changes for each ascending version   #
########################################################################################################

initial_version="0.0.0"
data_version_file=$project_base_dir/.data.version
old_version_file=$project_base_dir/.db.version
deltas_path=$project_base_dir/$deltas_dir

cli_user_file=$project_base_dir/datasets/cli_users.sql
cursor_file=$project_base_dir/datasets/cursor.sql
devlog_table_file=$project_base_dir/datasets/tx_devlog.sql
domain_record_file=$project_base_dir/html/local/config/domain-record.sql

if [ $? != 0 ]
then
	usage
	exit 2
fi

########################################################################################################
#		Retrieving DB Version (Set or Unset) And applying version changes for each ascending version   #
########################################################################################################

if [ ! -e $data_version_file ] ; then

	if [ ! -e $old_version_file ] ; then
		# SET IFEMPTY CURRENT VERSION
		echo "$initial_version" > "$data_version_file"
		echo_line "$data_version_file set to $initial_version"
	else
		# The previous version of this script used .db.version for recording the
		# data version.
		mv $old_data_version_file $data_version_file
	fi
fi

# GET CURRENT VERSION
current_version=`cat $data_version_file`

######################################
#	Update database based on TCA	 #
######################################
echo_line "clear TYPO3 configuration cache"
rm -f $project_base_dir/${www_dir}/typo3conf/temp_CACHED_*

#echo "$scriptname: remove all files in typo3temp (leaving directories in tact)"
#find ${www_dir}/typo3temp -type f -exec rm -f '{}' +
#rm -rf $project_base_dir/${www_dir}/typo3temp/*


#
# Set MySQL Acces properties
#
echo_line "Get DB parameters:"
. $scriptdir/get-db-config.sh -b $project_base_dir -w $www_dir

echo_line "Check if CLI-user t3deploy already exists"

cliuserexists=`mysql --host=$target_host --port=$target_port -u $target_username -p"$target_password" -Bse"use $target_database; select COUNT(*) from be_users where username=\"_cli_t3deploy\""`
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Table be_users should exist at this point, if not, exit script! Maybe you forgot to select a dataset for the first deployment? (Installation incomplete)"; exit 1; fi
if [ $cliuserexists -eq 0 ] ; then
	echo_line "    No, insert into DB:"
	mysql_import $cli_user_file
else
	echo_line "    Backend user _cli_t3deploy exists."
fi

if [ -e $devlog_table_file ] ; then
	echo_line "    Create table tx_devlog if it doesn't exist yet"
	mysql_import $devlog_table_file
fi

#if [ -e $devlog_table_file ] ; then
#	echo_line "    Create table tx_devlog if it doesn't exist yet"
#	mysql_import $devlog_table_file
#fi

if [ -e $domain_record_file ] ; then
	echo_line "    Create domain record"
	mysql_import $domain_record_file
fi

clear_cache

COUNTER=0
while [  $COUNTER -lt 1 ]; do
	echo_line "t3deploy - perform TCA database updates, round [$COUNTER]:"
	php $project_base_dir/${www_dir}/typo3/cli_dispatch.phpsh t3deploy database updateStructure --execute --allowkeymodifications
#	echo -e "\n$scriptname: typo3cms database:updateschema *.add,*.change, round [$COUNTER]:\n"
#	php $project_base_dir/${www_dir}/typo3cms database:updateschema "*.add,*.change"
	if [ "$?" -ne 0 ]; then echo_line "ERROR: Failed to perform TCA database updates. Installation incomplete"; exit 1; fi
	let COUNTER=COUNTER+1
done

# Apply SQL Patches to Database for every available SQL patch


tmp=`pwd`
cd $deltas_path
dirlist=`ls -1 | awk ' BEGIN { FS="." } { printf( "%03d.%03d.%03d\n",$1,$2,$3) }' | sort | awk ' BEGIN { FS="." } { printf( "%d.%d.%d ", $1,$2,$3) }'`
# Nicer alternative, but doesn't work on Mac:
#dirlist=`ls | sort --version-sort`
cd $tmp

#
# Function version, returns integer with 3 digits per version part
# 1.4.12 returns 1004012, etc.
#
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d\n", $1,$2,$3); }'; }

echo_line "Current version: $current_version ($(version $current_version))"

for delta in ${dirlist[@]}; do

	# Only apply patches with version higher than current db version
	# Compare version numbers using custom function version (see above)
	if [ $(version $delta) -gt $(version $current_version) ]; then

		echo "$scriptname: Delta version: $delta ($(version $delta))"

		if [ -d $deltas_path/$delta ]; then

			if [ "$do_database" -eq "1" ] ; then
				# Import DB deltas
				echo "$scriptname:     Patching DB version: $current_version => $delta"
				update=$deltas_path/$delta/updates.sql
				if [ -e $update ]; then
					mysql_import $update
					if [ "$?" -ne 0 ]; then
						echo
						echo "$scriptname: Debug Information"
						echo "   Path: $update"
						echo "   Current version: $current_version"
						echo "   Version: $delta"
						echo "   Update:  $deltas_path"
						echo "   ERROR: Failed update $delta. INSTALLATION INCOMPLETE";
						echo
						exit 1
					fi
				else
					echo_line "    NOT FOUND: patch SQL for update: $delta not found";
				fi
			fi

			if [ "$do_files" -eq "1" ] ; then
				# Import file deltas
				if [ -d $deltas_path/$delta/files ]; then
					echo "$scriptname: Copy file deltas \"$deltas_path/$delta/files\" to local installation (force overwrite)"
					cp -af $deltas_path/$delta/files/. $project_base_dir/${www_dir}/
				fi
			fi

			if [ "$do_scripts" -eq "1" ] ; then
				# Process script deltas
				if [ -e $deltas_path/$delta/updates.sh ]; then
					echo "$scriptname: Execute shell script as part of update: $delta/updates.sh"
					cd ${project_base_dir}/${www_dir}
					. ../$deltas_path/$delta/updates.sh
					if [ "$?" -ne 0 ]; then
						echo_line "ERROR: could not perform scripted deltas from $deltas_path/$delta/updates.sh"
					fi
					cd ${project_base_dir}
				fi
			fi

		fi

		# Update $current_version and data_version_file
		current_version=$delta
		echo "$current_version" > "$data_version_file"
	fi

done

current_version=`cat $data_version_file`

###################################
# End Applying DB Version changes #
###################################


###################################
# Clear configuration cache & all caches #
###################################

#echo -e "\n$scriptname: typo3cms - update reference index:\n"
#php $www_dir/typo3cms cleanup:updatereferenceindex --verbose
#if [ "$?" -ne 0 ]; then echo "$scriptname: WARNING: Failed to update reference index. Installation continues."; fi

clear_cache

#echo -e "\n$scriptname: typo3cms - warm up caches:"
#php $www_dir/typo3cms cache:warmup
#if [ "$?" -ne 0 ]; then echo_line "WARNING: Failed to warm-up caches using typo3_console script. Installation continues."; fi


###################################
# End Applying DB Version changes #
###################################

if [ "$increase_db_cursor" -eq 1 ] ; then

	if [ -e $cursor_file ] ; then
		echo_line "Raise database cursor for remote deployment"
		mysql_import $cursor_file
	else
		echo_line "WARNING: $cursor_file does not exist, continue anyway...."
	fi

fi
