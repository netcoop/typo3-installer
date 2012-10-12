#!/bin/bash
binDir=/usr/bin/

set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

get_version_config()
{
	if [ ! -e $target_localconf_file ]; then
		echo "$scriptname: ERROR: No config in $1. Aborting"
		exit 1
	fi

	export target_version=`grep '^ *\$TYPO3_CONF_VARS\[.SYS.\]\[.compat_version.\]' $target_localconf_file | sed -e 's/^ *\$TYPO3_CONF_VARS\[.SYS.\]\[.compat_version.\] *= *\(.*\).*;$/\1/' | tr -d "'"`
	echo "$scriptname: TYPO3 version (as set in $target_localconf_file) = $target_version"
}

# Usage: create_symlink <target> <link>
function create_symlink ()
{
	# check if file exists, we don't care if it is a symlink or not
	# skip if it exists
	if [ ! -L $2 ] ; then
		if [ ! -e $2 ] ; then
			# create symlink
			ln -s $1 $2
			echo "$scriptname: symlink created: $2 -> $1"
		fi
	fi
}

# Usage: update_symlink <target> <link>
function update_symlink ()
{
	# check if file exists, and is a symlink, rm it and create new
	if [ -L $2 ] ; then
		echo "$scriptname: remove $2 symlink"
		rm $2
	fi
	if [ -e $2 ] ; then
		echo "$scriptname: WARNING: $2 exists but is not a symlink!"
		return 0
	else
		ln -s $1 $2
		echo "$scriptname: create new symlink: $2 -> $1"
	fi
}

scriptname=$(basename $0)
scriptdir=$(dirname $0)
set_project_dir
www_dir="html"
typo3_src_path="../../src"

args=`getopt b:c:s:w: $*`
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
			target_localconf_file="$2";
			echo "Configuration: $target_localconf_file"
			shift;
			shift;;
		-s)
			typo3_src_path="$2";
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

if [ -z $target_localconf_file ] ; then
	target_localconf_file=${project_base_dir}/${www_dir}/typo3conf/localconf.php
fi

echo "$scriptname: Create TYPO3 symlinks if necessary in $project_base_dir/$www_dir"

get_version_config $target_localconf_file

cd $project_base_dir/${www_dir}

update_symlink $typo3_src_path/typo3_src-$target_version typo3_src
create_symlink typo3_src/typo3 typo3
create_symlink typo3_src/t3lib t3lib
create_symlink typo3_src/index.php index.php

cd $tmp