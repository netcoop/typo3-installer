#!/bin/bash
binDir=/usr/bin/

function set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

function get_version_config()
{
	export typo3_version=`php $scriptdir/get-typo3-conf.php ${project_base_dir}/${www_dir} SYS compat_version`
	echo "$scriptname: TYPO3 version (as set in TYPO3 local configuration file) = $typo3_version"
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

# Usage: remove_symlink <target> <link>
function remove_symlink ()
{
	# check if file exists, and is a symlink, rm it
	if [ -L $1 ] ; then
		echo "$scriptname: remove $1 symlink"
		rm $1
	fi
}

# Usage: update_symlink <target> <link>
function update_symlink ()
{
	remove_symlink $2
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

args=`getopt b:s:t:w: $*`
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
		-s)
			typo3_src_path="$2";
			shift;
			shift;;
		-t)
			typo3_version="$2";
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

echo "$scriptname: Create TYPO3 symlinks if necessary in $project_base_dir/$www_dir"

if [ -z "${typo3_version+x}" ]; then
	# If typo3_version has not been set using the command line parameter -t, then get it from the localconf/LocalConfiguration.php files
	get_version_config
	if [ -z "${typo3_version+x}" ]; then
		# Still not set, then assume v7.6 (since the setting [SYS][compat_version] has been removed in v7.1 and this is the first LTS since
		typo3_version="7.6"
		echo "$scriptname: TYPO3 version (default, as other options failed) = $typo3_version"
	fi
else
	echo "$scriptname: TYPO3 version (as provided in command-line paramater -v) = $typo3_version"
fi

cd ${project_base_dir}/${www_dir}

if [ "${typo3_version:0:1}" -ge "6" ]; then
	cd typo3conf
	update_symlink ../local/config/AdditionalConfiguration.php AdditionalConfiguration.php
	cd ..
fi

if [[ "${typo3_version:0:3}" == "6.2" ]] || [ "${typo3_version:0:1}" -ge "7" ] ; then
	remove_symlink t3lib
else
	create_symlink typo3_src/t3lib t3lib
fi

if [ -n "$typo3_version" ]; then
	update_symlink ${typo3_src_path}/typo3_src-${typo3_version} typo3_src
fi
create_symlink typo3_src/typo3 typo3
create_symlink typo3_src/index.php index.php

cd $tmp
