#!/bin/bash
binDir=/usr/bin/

#
# usage: replace-local-database.sh [<data-set>]
#

tstamp=`date +-%Y%m%d-%H%M`

scriptdir=$(dirname $0)
project_base_dir=$scriptdir/..

if [ -z "$1" ]; then
	. $scriptdir/apply-dataset.sh -d
else
	. $scriptdir/apply-dataset.sh -d -n $1
fi

if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to apply dataset. Installation incomplete"; exit 1; fi

cd "$project_base_dir"
. $scriptdir/apply-deltas.sh -d

echo
echo "Done, GO GO GO GO!"
echo
