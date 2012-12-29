#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo ""
	echo "Restore the specified backup (as created by create-backup.sh)."
	echo "If no version no is provided, the latest backup will be used."
	echo ""
	echo "ATTENTION: at this moment, only 1 dataset can be made for 1 version number."
	echo ""
	echo "Usage: $scriptname -d<name>"
	echo "	-b <dir>  : specify project base <dir>"
	echo "	-v <version> : version number of the backup to use for this dataset"
	echo "		<version> can be 2, 2.0 or 2.0.1.3 - the latest available backup of this version is used"
	echo "	-f		: only copy files"
	echo "	-d		: only import database"
	echo "	-s		: only run update scripts (not implemented)"
	echo ""
}

set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

mysql_import()
{
	echo "$scriptname:     Import $1 into $target_database..."
	mysql --host=$target_host --port=$target_port -u $target_username -p"$target_password" $target_database --default-character-set=utf8 < $1
	if [ "$?" -ne 0 ]; then echo "$scriptname: ERROR: Failed to import $1."; exit 1; fi
}

##
##	Apply dataset from directory $1
##	Second option can be "-n" for copy command (do not overwrite existing files)
##
apply_dataset()
{
	echo "$scriptname: ---------------------------------------------------------------------"
	if [ ! -d "$1" ]; then
		echo "$scriptname: Dataset $1 does not exist"
		exit 1
	else
		echo "$scriptname: Start importing dataset $1"
		cd $1

		copy_option="-f"
		extract_option=""

		# Do not overwrite existing files If second parameter is -n
		if [ ! -z $2 ]; then
			if [ "$2" == "-n" ]; then
				copy_option="-n"
				extract_option="-k"
			fi
		fi

		if [ "$do_database" -eq "1" ] ; then

			echo "$scriptname: Import sql files from dataset into $target_database:"

			if [ ! -d sqltemp ]; then
				mkdir sqltemp
			fi

			# Extract compressed sql files...
#			find * -maxdepth 0 -type f -iname "*.sql.tar.gz" -or -iname "*.sql.tgz" -exec tar -xzf "{}" -C "$1/sqltemp" \;
			echo "$scriptname: Untar compressed sql files from \"$1\" to temporary dir"
			for tgzfile in *.sql.tar.gz
			do
				if [ ! "$tgzfile" == "*.sql.tar.gz"  ] ; then
					echo "Untar temp $tgzfile"
					tar -xzf "$tgzfile" -C "$1/sqltemp"
				fi
			done

			# Import unpacked sql files
			cd sqltemp

			for sqlfile in *.sql
			do
				if [ ! "$sqlfile" == "*.sql"  ] ; then
					mysql_import "$sqlfile"
				fi
			done

			cd ..
			# Remove temp dir
			rm -rf sqltemp

			# Import uncompressed sql files
			echo "$scriptname: Import .sql files into database"
			#find * -maxdepth 0 -type f -iname *.sql -exec echo "{}" \;
			for sqlfile in *.sql
			do
				if [ ! "$sqlfile" == "*.sql"  ] ; then
					mysql_import "$sqlfile"
				fi
			done
		fi

		# First unpack all tar.gz archives found
		# Then copy tree structure under 'files'

		if [ "$do_files" -eq "1" ]; then
			# Unpack any tar.gz or tgz files directly into ${www_dir} dir
			if [ -f *.files.tar.gz ] ; then
				echo "$scriptname: Untar files from dataset \"$1\" to local installation"
				find * -maxdepth 0 -type f -iname "*.files.tar.gz" -exec tar -xz $extract_option -f "{}" -C "$project_base_dir/$www_dir" \;
				#tar -xz $extract_option -f "live.files.tar.gz" -C "$project_base_dir/$www_dir"
			fi
			if [ -d "files" ] ; then
				echo "$scriptname: Copy files from dataset \"$1\" to local installation"
				cp -a $copy_option "$1/files/". "$project_base_dir/${www_dir}/"
			fi
		fi

		# TODO: add scripts ?
		# Same as update script!

		# Set data_version_file to version of this dataset
		this_version=`echo "$(basename $1)" | sed 's/\([0-9]*.[0-9]*.[0-9]*\)\.*.*/\1/'`
		echo "$scriptname: Set version to $this_version ($1)"
		echo "$this_version" > "$data_version_file"

	fi
}

# Use gnutar if available (e.g. on MacOSX)
tar=tar
which gnutar > /dev/null 2>&1 && tar=`which gnutar`

scriptname=$(basename $0)
scriptdir=$(dirname $0)
set_project_dir
data_version_file=$project_base_dir/.data.version
backup_dir=$project_base_dir/backup
www_dir="html"

do_files=1
do_database=1
do_scripts=1

args=`getopt b:v: $*`
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
		-f)
			do_files=1;
			do_database=0;
			do_scripts=0;
			shift;;
		-d)
			do_files=0;
			do_database=1;
			do_scripts=0;
			shift;;
		-s)
			do_files=0;
			do_database=0;
			do_scripts=1;
			shift;;
		-v)
			versionno="$2";
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

. $scriptdir/get-db-config.sh -w $www_dir


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

# Project version no for this backup is first 3 parts of backup version
backup_project_version=`echo "$backup_version" | sed 's/\([0-9]*.[0-9]*.[0-9]*\).[0-9]*/\1/'`

apply_dataset "$project_base_dir/backup/$backup_version"


echo "$scriptname: Successfully restored backup/$backup_version"
echo

