#!/bin/bash
binDir=/usr/bin/

usage()
{
	echo "Usage: $scriptname"
	echo "	-v <version>	: apply dataset <version>"
	echo "	-n <name>	: apply dataset <name>"
	echo "	-b <dir>	: specify project base <dir> ($project_base_dir)"
	echo "	-w <dirname>	: specify name of www directorybackup <dirname> ($www_dir)"
	echo "	-f		: only copy files"
	echo "	-d		: only import database"
	echo "	-s		: only run update scripts"
}

set_project_dir()
{
	tmp=`pwd`
	cd $scriptdir/..
	project_base_dir=`pwd`
	cd $tmp
}

rm_ifexists()
{
	for ARG in "$@" ; do
		if [ -e "$ARG" ] ; then
			echo "$scriptname:     remove $ARG"
			rm -rf "$ARG"
		fi
	done
	return $?
}

mysql_import()
{
	echo "$scriptname:     importing $1"
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

scriptname=$(basename $0)
scriptdir=$(dirname $0)
set_project_dir
data_version_file=$project_base_dir/.data.version
datasetversion=""
datasetname=""
www_dir="html"

do_files=1
do_database=1
do_scripts=1

args=`getopt fdsv:n:b:w: $*`
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
		-v)
			datasetversion="$2";
			shift;
			shift;;
		-n)
			datasetname="$2";
			shift;
			shift;;
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

cd "$project_base_dir"
mkdir -p datasets datasetslocal

importdataset=0
# If version and/or name is specified
if [ ! -z "$datasetversion" ] || [ ! -z "$datasetname" ]; then

	dataset_regex="^$datasetversion.*$datasetname$"
	echo "$scriptname: Looking for dataset matching: ${dataset_regex}..."
	# Get latest directory that matches version and/or name
	dirlist=`(ls $project_base_dir/datasets/; ls $project_base_dir/datasetslocal/) | grep $dataset_regex | sort -r`
	set -- $dirlist
	dataset=$1

	if [ -z "$dataset" ]; then
		echo "$scriptname: ERROR: specified dataset $dataset does not exist"
	else
		# Check if dataset exists in datasetslocal, if not try directory datasets
		if [ -d $project_base_dir/datasetslocal/$dataset ]; then
			datasetdir=$project_base_dir/datasetslocal/$dataset
		else
			if [ -d $project_base_dir/datasets/$dataset ]; then
				datasetdir=$project_base_dir/datasets/$dataset
			else
				echo "$scriptname: ERROR: dataset $dataset does not exist"
				exit 1;
			fi
		fi
		importdataset=1
		echo "$scriptname:     dataset $dataset found"
	fi
fi

if [ "$do_files" -eq "1" ]; then
	echo "$scriptname: Delete site directories from .rsync-exclude file (typically fileadmin, uploads and typo3temp)"

	dirstoremove=( $( < "$project_base_dir/.rsync-exclude" ) )
	cd "$project_base_dir/${www_dir}"
	for dtr in "${dirstoremove[@]}" ; do
		if [[ "${dtr}" =~ ^fileadmin|uploads|typo3temp ]] ; then
			rm_ifexists "${dtr}"
		fi
	done
fi

if [ "$do_database" -eq "1" ]; then
	echo "$scriptname: Drop all tables in database"
	mysqldump --host=$target_host --port=$target_port -u $target_username -p"$target_password" --add-drop-table --no-data $target_database | grep ^DROP | mysql --host=$target_host -u $target_username -p"$target_password" $target_database
fi

# apply base dataset with 'do not overwrite' option (for typo3conf dir, the others are empty anyway)
apply_dataset "$project_base_dir/datasets/0.0.0" "-n"

#echo "importdataset: $importdataset - datasetdir: $datasetdir"
if [ $importdataset -eq 1 ]; then
	apply_dataset "$datasetdir"
fi

echo "$scriptname: ---------------------------------------------------------------------"

if [ "$do_files" -eq "11" ]; then
	echo "$scriptname: Set file permissions according to configuration"
	cd $project_base_dir
	. $scriptdir/apply-permissions.sh -w $www_dir
fi

cd $project_base_dir
echo "$scriptname: Done"
echo

