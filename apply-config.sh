#!/bin/bash
binDir=/usr/bin/

scriptname=$(basename $0)
scriptdir=$(dirname $0)
project_base_dir=$scriptdir/..

if [ -z "$1" ]; then
	echo
	echo "Usage: $scriptname:"
	echo "	apply-config.sh <config-dir> [<project_base_dir>]"
	echo
	echo "	Available configurations:"
	find "$project_base_dir/config/"* -maxdepth 0 -type d -printf "\t\t%f\n"
	echo
	exit 1
else
	config=$1
	if [ ! -z "$2" ]; then
		project_base_dir=$2
	fi
	config_dir=$project_base_dir/config/$config

	if [ ! -d $config_dir ] ; then
		echo "$scriptname: config/$config doesn't exist"
		exit 1
	else
		if [ ! -d $project_base_dir/html/local ]; then
			mkdir $project_base_dir/html/local
		fi
		echo "$scriptname: Applying configuration $config"
		
		old=`pwd`
		cd $project_base_dir/html/local
		rm -f config
		ln -s ../../config/$config config
		cd $old
	fi
fi