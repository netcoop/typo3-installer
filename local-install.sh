#!/bin/bash
binDir=/usr/bin/

#############################
# LOCAL INSTALLATION SCRIPT #
#############################

########### TODO:
######## - Create Database option: if root pw is provided (on command line?)

usage()
{
	echo "Usage: $scriptname"
	echo "	-n <name>	: specify dataset <name> or <version.name>"
	echo "	-e <config>	: specify config <dir> (configuration directory name)"
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
datasetname=""

args=`getopt e:n: $*`
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
		-n)
			datasetname="-n $2";
			shift;
			shift;;
		-e)
			environment_config="$2";
			shift;
			shift;;
		--)
			shift;
			break;;
	esac
done

#
# APPLY CONFIG
#
if [ ! -z "$environment_config" ] ; then
	echo "$scriptname: Apply config"
	. $scriptdir/apply-config.sh "$environment_config"
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to apply config. Installation incomplete"; exit 1; fi
fi

#
# APPLY SYMLINKS
#
echo "$scriptname: Apply symlinks"
. $scriptdir/apply-symlinks.sh
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to apply symlinks. Installation incomplete"; exit 1; fi

#
# APPLY DIRECTORY STRUCTURE
#
echo "$scriptname: Set up local directory structure"
. $scriptdir/apply-directory-structure.sh
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to set up local directory structure. Installation incomplete"; exit 1; fi

#
# APPLY PERMISSIONS
#
echo "$scriptname: Apply permissions"
. $scriptdir/apply-permissions.sh
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to apply permissions. Installation incomplete"; exit 1; fi

#
# Create Required Directories
#
echo "$scriptname: Apply dataset ${datasetname}"
. $scriptdir/apply-dataset.sh "${datasetname}"
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to apply dataset. Installation incomplete"; exit 1; fi

#
# APPLY DELTAS
#
echo "$scriptname: Apply deltas"
. $scriptdir/apply-deltas.sh
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to apply database updates. Installation incomplete"; exit 1; fi

echo "$scriptname: Done!"

exit 0