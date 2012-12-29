#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo "Usage: $scriptname"
	echo "	-b <dir>  : specify project base <dir> ($project_base_dir)"
	echo "	-w <dirname> : specify name of www directorybackup <dirname> ($www_dir)"
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
www_dir="html"
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

# Get dbconfig only for getting $target_apache_user_group
. $scriptdir/get-db-config.sh -w $www_dir

echo "$scriptname: Set permissions, leave x-bit alone"
echo "$scriptname: Allow apache to write in certain TYPO3-directories and set sticky bit on directories"

tmppath=`pwd`

cd $project_base_dir/${www_dir}
if [ ! -z "$target_apache_user_group" ] ; then
	chgrp -fR $target_apache_user_group fileadmin/ typo3conf/ typo3temp/ uploads/ local/
	if [ "$?" -ne 0 ]; then echo "$scriptname: WARNING: Failed to set group $target_apache_user_group on installed files"; fi
fi
chmod -fR u+rw,g+rw,o-w,o+r fileadmin/ typo3conf/ typo3temp/ uploads/ local/log
if [ "$?" -ne 0 ]; then echo "$scriptname: WARNING: Failed to set mode on installed files"; fi
find fileadmin/ typo3conf/ typo3temp/ uploads/ local/ -type d -exec chmod -f g+s,a+rx {} \;
if [ "$?" -ne 0 ]; then echo "$scriptname: WARNING: Failed to set sticky bit on installed files"; fi

cd $tmppath
echo
