#!/bin/bash
binDir=/usr/bin/

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
	echo "$*"
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



createdirs=(
datasets
datasetslocal
log
${www_dir}/local/log
${www_dir}/typo3temp
${www_dir}/uploads
)

cd $project_base_dir

echo "$scriptname: Create required directories... (project_base_dir = $project_base_dir)"

for createdir in ${createdirs[@]} ; do
	if [ ! -d ${createdir} ] ; then
		echo "$scriptname: Create directory: ${createdir}"
		mkdir -p ${createdir}
		if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to create ${createdir} directory. Installation incomplete"; exit 1; fi
	fi
done

cd $tmp
