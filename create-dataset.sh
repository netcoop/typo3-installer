#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo ""
	echo "Create a dataset out of the specified backup (as created by create-backup.sh)."
	echo "If no version no is provided, the latest backup will be used."
	echo "By default, datasets are compressed and stored in directory datasetslocal/<version-no>"
	echo "To create a global dataset (under version control and uncompressed), use the -g option, or"
	echo "simply move the sub-directory <version-no> to directory 'datasets' and unpack the tars"
	echo ""
	echo "ATTENTION: at this moment, only 1 dataset can be made for 1 version number."
	echo ""
	echo "Usage: $scriptname -d<name>"
	echo "	-b <dir>  : specify project base <dir>"
	echo "	-n <name> : create dataset with <name>"
	echo "	-g  : create global dataset in directory datasets"
	echo "	-v <version> : version number of the backup to use for this dataset"
	echo "		<version> can be 2, 2.0 or 2.0.1.3 - the latest available backup of this version is used"
	echo ""
}

set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

# Use gnutar if available (e.g. on MacOSX)
tar=tar
which gnutar > /dev/null 2>&1 && tar=`which gnutar`

scriptname=$(basename $0)
scriptdir=$(dirname $0)
set_project_dir
backup_dir=$project_base_dir/backup

#default values for command line settings
global_dataset=0
dataset_name="dataset"

args=`getopt gb:n:v: $*`
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
		-n)
			dataset_name="$2";
			shift;
			shift;;
		-v)
			versionno="$2";
			shift;
			shift;;
		-g)
			global_dataset=1;
			shift;;
		--)
			shift;
			break;;
	esac
done

if [ "$global_dataset" -eq 1 ]; then
	dataset_dir="$project_base_dir/datasets"
else
	dataset_dir="$project_base_dir/datasetslocal"
fi

# TODO: cleanup
# Determine latest backup:
#dirlist=`ls -1 | awk ' BEGIN { FS="." } { printf( "%03d.%03d.%03d.%03d\n",$1,$2,$3,$4) }' | sort | awk ' BEGIN { FS="." } { printf( "%d.%d.%d.%d ", $1,$2,$3,$4) }'`

if [ ! -d "$backup_dir" ]; then echo "$scriptname: Backup directory '$backup_dir' does not exist"; exit 1; fi
cd $backup_dir

version_sort_option="--version-sort "
dirlist=`ls | sort "$version_sort_option"-r 2>&1 /dev/null`
if [ "$?" -ne 0 ]; then
	# If --version-sort is not available (as is on Mac), then fallback on alfabetic sorting
	dirlist=`ls -r`
	version_sort_option=""
fi

# If isset($versionno)
if [ -n "${versionno+x}" ]; then
	# List only sub-versions of specified main version
	dirlist=`ls | grep ^$versionno | sort "$version_sort_option"-r`
fi
set -- $dirlist
backup_version=$1

# Version no for dataset will be first 3 parts of backup version + dataset_name
dataset_version_name=`echo "$backup_version" | sed 's/\([0-9]*.[0-9]*.[0-9]*\).[0-9]*/\1/'`".$dataset_name"

echo "$scriptname: Creating dataset $dataset:"
echo "$scriptname:     location: $dataset_dir/$dataset_version_name"
echo "$scriptname:     based on: $backup_dir/$backup_version"

if [ -d "$dataset_dir/$dataset_version_name" ]; then
	echo "$scriptname: ERROR: a dataset with this name and version already exists!"
	exit 1
fi

mkdir -p "$dataset_dir/$dataset_version_name/files"
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to create directory $dataset_dir/$dataset_version_name/files"; exit 1; fi

dirlist=`ls "$backup_dir/$backup_version"`

$tar -xzf "$backup_dir/$backup_version/"*.files.tar.gz -C "$dataset_dir/$dataset_version_name/files" --anchored --exclude="typo3conf" --exclude="local/log" --exclude="local/config"
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to unpack webdirectory files."; rm -rf "$dataset_dir/$dataset_version_name"; exit 1; fi

exclude_tables=(
be_sessions
cache_extensions
cache_hash
cache_imagesizes
cache_md5params
cache_pages
cache_pagesection
cache_sys_dmail_stat
cache_treelist
cache_typo3temp_log
cachingframework_cache_hash
cachingframework_cache_hash_tags
cachingframework_cache_pages
cachingframework_cache_pagesection
cachingframework_cache_pagesection_tags
cachingframework_cache_pages_tags
index_debug
index_fulltext
index_grlist
index_phash
index_rel
index_section
index_stat_search
index_stat_word
index_words
fe_sessions
fe_session_data
sys_dmail
sys_dmail_maillog
sys_history
sys_lockedrecords
sys_log
sys_refindex
tx_crawler_configuration
tx_crawler_process
tx_crawler_queue
tx_devlog
tx_pbsurvey_answers
tx_realurl_chashcache
tx_realurl_errorlog
tx_realurl_pathcache
tx_realurl_uniqalias
tx_realurl_urldecodecache
tx_realurl_urlencodecache
tx_solr_last_searches
tx_solr_statistics
)

excludes=""
for excludefile in "${exclude_tables[@]}"
do
	excludes="$excludes--exclude=$excludefile.sql "
done

$tar -xzf "$backup_dir/$backup_version/"*.sql.tar.gz -C "$dataset_dir/$dataset_version_name" $excludes
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to unpack sql files."; rm -rf "$dataset_dir/$dataset_version_name"; exit 1; fi

## Compress files in case we're creating a local dataset:
if [ "$global_dataset" -eq 1 ]; then
	echo "$scriptname: skipped compressing because we're creating a global dataset (which should be in VCS)"
else
	echo "$scriptname: Compress dataset in datasetslocal"
	cd "$dataset_dir/$dataset_version_name"
	$tar -czf ${dataset_name}.sql.tar.gz --remove-files *.sql
	if [ "$?" -ne 0 ]; then
		echo "$scriptname: ERROR: Failed to compress databasedumps into sql.tar.gz file. Compressing dataset failed"; exit 1
	else
		echo "$scriptname: sql files compressed in ${dataset_name}.sql.tar.gz"
	fi
	cd files
	$tar -czf ../${dataset_name}.files.tar.gz --remove-files .
	if [ "$?" -ne 0 ]; then
		echo "$scriptname: ERROR: Failed to compress files into files.tar.gz file. Compressing dataset failed"; exit 1
	else
		cd ..
		rm -rf files
		echo "$scriptname: sql files compressed in ${dataset_name}.files.tar.gz"
	fi

fi

echo "$scriptname: Successfully created dataset in $dataset_dir/$dataset_version_name"

exit 0
