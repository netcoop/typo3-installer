#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo "Usage: $scriptname"
	echo "	-b <dir>  : specify project base <dir> ($project_base_dir)"
	echo "	-f <name> : specify backup <name> ($backup_name)"
	echo "	-w <dirname> : specify name of www directorybackup <dirname> ($www_dir)"
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

error=0
scriptname=$(basename $0)
scriptdir=$(dirname $0)
set_project_dir
www_dir="html"

args=`getopt b:f:w: $*`
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
		-f)
			backup_name="$2";
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

# Get DB properties
. $scriptdir/get-db-config.sh -w $www_dir

# Read value for $projectVersion from file
if [ -e .data.version ]; then
	projectVersion=`cat .data.version`
else

	if [ -e .db.version ]; then
		projectVersion=`cat .db.version`
	else
		# No version.properties found
		projectVersion="0.0.0"
	fi
fi

echo "$scriptname: Backing up installation at $project_base_dir/$www_dir"

if [ ! -d $project_base_dir/$www_dir ]; then
	echo "$scriptname: Directory $www_dir not found, cowardly refusing to create empty backup of $project_base_dir/$www_dir"
	exit 0
fi

# Create first available backup dir for this version
#i="0"
#while [ -d "$project_base_dir/backup/$projectVersion.$i" ]
#do
#	echo "$scriptname: Directory backup/${projectVersion}.$i already exists..."
#	i=$[$i+1]
#	if [ $i -gt 99 ] ; then
#		echo "$scriptname: Too many backups for this version, clean-up and try again"
#		exit 1
#	fi
#done

if [ ! -d "$project_base_dir/backup" ]; then
	mkdir "$project_base_dir/backup"
fi
cd "$project_base_dir/backup"

dirlist=`ls | grep ^$projectVersion | sort --version-sort -r`
if [ "$?" -ne 0 ]; then
	# If --version-sort is not available (as is on Mac), then fallback on alfabetic sorting
	dirlist=`ls -r | grep ^$projectVersion`
fi

if [ "$dirlist" == "" ]; then
	backup_version="$projectVersion.0"
else
	set -- $dirlist
	backup_version=$1

	# Increment version nr. by 1
	[[ "$backup_version" =~ (.*\.)([0-9]+)$ ]]
	backup_version="${BASH_REMATCH[1]}$((${BASH_REMATCH[2]} + 1))"
fi

echo "$scriptname: Creating backup directory backup/$backup_version"

mkdir -p "$project_base_dir/backup/$backup_version"
if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed create directory backup/$backup_version. Backup failed"; exit 1; fi

if [ -z "$backup_name" ]; then
	backup_name=${target_database}-`date +%Y%m%d-%H%M`
fi

backup_dir="$project_base_dir/backup/$backup_version"
backup_filepath="$project_base_dir/backup/$backup_version/$backup_name"

# Include .htaccess as _.htaccess (to backup site
cd $project_base_dir/$www_dir
copiedhtaccess=0
if [ ! -f "_.htaccess.disabled" ] && [ -f ".htaccess" ] ; then
	cp .htaccess _.htaccess.copy.by.create-backup.script
	copiedhtaccess=1
	echo "$scriptname: .htaccess copied to _.htaccess.copy.by.create-backup.script"
fi

# Attention: webroot backup does NOT include hidden files!
#$tar -cz --no-recursion -f ${backup_filepath}_webroot.tar.gz *

excludepaths=(
typo3conf/temp_CACHED_*
typo3temp
)
excludes=""
for excludepath in "${excludepaths[@]}"
do
	excludes="$excludes--exclude=$excludepath "
done

echo "$scriptname: Backup files to ${backup_filepath}.files.tar.gz"
#echo "$tar -cz --anchored $excludes-C $project_base_dir/$www_dir -f ${backup_filepath}.tar.gz *"
#echo "$tar -czf ${backup_filepath}.files.tar.gz --anchored $excludes*"
#sh -c "$tar -cz -f ${backup_filepath}.tar.gz --anchored $excludes*"
$tar -czf ${backup_filepath}.files.tar.gz --anchored $excludes*
tarerror="$?"

if [ $copiedhtaccess -ne 0 ] ; then
	#clean up htaccess copy
	rm _.htaccess.copy.by.create-backup.script
	echo "$scriptname: Temporary file _.htaccess.copy.by.create-backup.script removed"
fi
if [ "$tarerror" -ne 0 ]; then echo "$scriptname: ERROR: Failed to tar $www_dir/* to backup directory. Backup failed"; exit 1; fi

#
# backup config directory
#
echo "$scriptname: Backup local/config directory"
#`readlink $project_base_dir/$www_dir/local/config`
#echo $config_dir
if [ ! -d "$project_base_dir/$www_dir/local" ]
then
	echo "$scriptname: ERROR: Local config directory not found, continuing with other backup parts..."
	error=1
else
	cd "$project_base_dir/$www_dir"
	# $tar -h option is dereference: follow symlinks and copy as files
	$tar -chzf ${backup_filepath}.local_config.tar.gz --exclude="local/log" --anchored local
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to tar configuration files to backup directory. Backup failed"; exit 1; fi
fi

#
# backup the database
#
echo "$scriptname: Backup database"

if [ "$target_host" == "localhost" ] ; then
	target_scope=$target_host
else
	target_scope=%
fi

# Get array of all tables in database
alltables=($(mysql --host=$target_host --port=$target_port -u $target_username -p"$target_password" $target_database -Bse "show tables;"))
#echo "List all tables: $alltables"

# List of database tables to exclude from database dump
excludetables=(
cache_extensions
cache_imagesizes
cache_md5params
cache_treelist
cache_typo3temp_log
cf_cache_hash
cf_cache_hash_tags
cf_cache_pages
cf_cache_pagesection
cf_cache_pagesection_tags
cf_cache_pages_tags
)

ignoretables=""
for table in "${alltables[@]}"
do
#	if [[ "$table" =~ ^(cache_|cf_cache_).* ]]
#	then
#		ignoretables="$ignoretables--ignore-table=$target_database.$table "
#	else
		echo "$scriptname:     dump $table"
		mysqldump --host=$target_host --port=$target_port -u $target_username -p"$target_password" --add-drop-table --default-character-set=utf8 $target_database $table > ${backup_dir}/${table}.sql
		if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to dump database to backup directory. Backup failed"; exit 1; fi
#	fi
done

#echo "Ignore: $ignoretables"
#ignoretables=""
#for excludetable in "${excludetables}"
#do
#	ignoretables="$ignoretables--ignore-table=$target_database.$excludetable "
#done

#echo "mysqldump --host=$target_host --port=$target_port -u $target_username -p"$target_password" --add-drop-table $ignoretables--default-character-set=utf8 $target_database > $backup_filepath.sql"
#mysqldump --host=$target_host --port=$target_port -u $target_username -p"$target_password" $ignoretables--add-drop-table $target_database --default-character-set=utf8 > $backup_filepath.sql

cd ${backup_dir}
# Check if any .sql files exist
if ls *.sql > /dev/null 2>&1 ; then
	$tar -czf ${backup_filepath}.sql.tar.gz --remove-files *.sql
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to compress database backups into tar.gz file. Backup failed"; exit 1; fi
else
	echo "$scriptname: ERROR: No database tables dumped, probably database is empty or connection error!"
	exit 1;
fi

if [ "$error" -ne 0 ]
then
	echo "$scriptname: WARNING: At least one error occured, check the output of this script!"
else
	echo "$scriptname: Successfully created tars and sql backup $backup_filepath"
fi

exit 0
