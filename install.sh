#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo "Usage: $scriptname"
	echo "	-b <dir>			: specify project base <dir> ($project_base_dir)"
	echo "	-c <config name>	: specify configuration (see build.xml)"
	echo "	-x					: no backup"
	echo "	-r					: replace data"
}

set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

scriptname=$(basename $0)
scriptdir=$(dirname $0)
set_project_dir
target_config_file=$project_base_dir/install/config/localsettings.php

# Default Settings
keep_data=1
no_backup=0

args=`getopt xdfc:b: $*`
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
		-r)
			keep_data=0;
			echo "$scriptname: Keep Database"
			shift;;
		-b)
			project_base_dir="$2";
			echo "$scriptname: Project base: $project_base_dir"
			shift;
			shift;;
		-c)
			target_config_file="$2";
			echo "$scriptname: Configuration: $target_config_file"
			shift;
			shift;;
		-x)
			echo "$scriptname: No backup"
			no_backup=1;
			shift;;
		--)
			shift;
			break;;
	esac
done


#chmod 754 $scriptdir/*.sh
#if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to set executable mode on scripts. Installation incomplete"; exit 1; fi

if [ ! -d $project_base_dir/html ] ; then
	# no html directory found, this is the 1st ever installation
	mkdir $project_base_dir/html
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to html directory. Installation incomplete"; exit 1; fi
	if [ $no_backup != 1 ]; then
		echo "$scriptname: Initial installation, no backup required"
	fi
	# no neet to perform backup
	no_backup=1
fi

if [ $no_backup != 1 ]; then
	#
	# Create a backup before we go any further
	#
	$scriptdir/create-backup.sh -b $project_base_dir
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to create backup. Installation incomplete"; exit 1; fi
fi

#
# Take the site offline by rewriting all requests to sorry.html
#
echo "$scriptname: Take site off-line by directing all traffic to sorry-page"
if [ -f $project_base_dir/html/.htaccess ] ; then
	mv -f $project_base_dir/html/.htaccess $project_base_dir/html/.htaccess_backup
fi
echo -e "RewriteEngine on\nRewriteRule .* sorry.html" > $project_base_dir/html/.htaccess


if [ $keep_file_data = 1 ] ; then

	echo "$scriptname: Keep file data, skipping file updates (but still creating/fixing essential directories)"

else

	#
	# remove parts of old installation
	#
	if [ -d $project_base_dir/html ] ; then
		rm -rf $project_base_dir/html/typo3conf
		if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to remove files from old installation. Installation incomplete"; exit 1; fi
	fi

	#
	# deploy the files to the site dir
	#
	echo "$scriptname: Unpack project core files..."
	tar xzf $project_base_dir/core.tgz -C $project_base_dir/html/
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to untar core.tgz"; exit 1; fi
	rm  $project_base_dir/core.tgz

fi


###############################################################################################
#	Apply the chosen configuration for this deployment										  #
###############################################################################################

	install_config_dir=$project_base_dir/install/config

	if [ ! -d $project_base_dir/html/localsettings ]; then
		mkdir -p $project_base_dir/html/localsettings
	fi

	if [ ! -d $install_config_dir ] ; then
		echo "$scriptname: dir $install_config_dir doesnt exist, no new configuration found to apply"
	else
		echo "$scriptname: Applying configuration from $install_config_dir"
		cp -f $install_config_dir/* $project_base_dir/html/localsettings/
	fi

###############################################################################################
#	Create essential directories															  #
###############################################################################################

. $scriptdir/apply-directory-structure.sh

###############################################################################################
#	Apply Symlinks																			  #
###############################################################################################

. $scriptdir/apply-symlinks.sh

###################################################################################################
#   Start Check DB version to keep active data, else it drops the tables & inserts all new tables #
###################################################################################################

if [ $keep_db_data = 1 ] ; then
	echo "$scriptname: Keep DB data, skipping apply-initial-database"
else
	echo "$scriptname: $scriptdir/apply-initial-database.sh -r"
	. $scriptdir/apply-initial-database.sh -r
fi

########################################################################################################
#		Retrieving DB Version (Set or Unset) And applying version changes for each ascending version   #
########################################################################################################

echo "$scriptname: Apply database updates...."
. $scriptdir/apply-deltas.sh -r
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed apply updates. Installation incomplete"; exit 1; fi

#####################################################################
#	Put site back on line by putting back the original .htaccess	#
#####################################################################

echo "$scriptname: Put site back on-line by restoring original .htaccess"
mv $project_base_dir/html/.htaccess_backup $project_base_dir/html/.htaccess


###################################
# TODO
# Apply AW stats #
###################################

echo "$scriptname: Create AW stats log file directory if it does not exist yet..."
if [ ! -e "$project_base_dir/html/localsettings/logs" ] ; then
	mkdir $project_base_dir/html/localsettings/logs
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to create AW stats log file directory. Installation incomplete"; exit 1; fi
fi

######################################################################
# Apply the configured permissions									 #
######################################################################

. $scriptdir/apply-permissions.sh

echo "$scriptname: Done!"

exit 0
