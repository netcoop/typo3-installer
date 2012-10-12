#!/bin/bash
binDir=/usr/bin/

scriptname=$(basename $0)
cd "$(dirname "$0")"
#echo "scriptdir = $scriptdir"

. lib-include.sh

echo
echo "$scriptname: There we go with test.sh!"

pwd


echo "scriptdir = $scriptdir"
echo "initial_version = $initial_version"
echo "project_base_dir = $project_base_dir"

cd "$project_base_dir"
excludes=( $( < ".rsync-exclude" ) )

echo -e " Number of elements in array is $(( ${#excludes[@]} )) \n"
#for i in $(seq 0 $((${#excludes[@]} - 1)))
for ex in "${excludes[@]}"
do
	if [[ ${ex} =~ ^fileadmin|typo3temp|uploads ]] ; then
		echo ${ex}
	fi
done

echo -e ""

cd ~/www/bris.nl/datasetslocal/0.0.0.live
find * -maxdepth 0 -type f -iname "*.files.tar.gz" -exec echo {} \;

#lib_error Bla
