#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"
source "$(dirname $(realpath ${0}))/secrets.cfg"


verify_command duplicity || die "duplicity is required for backing up encrypted photos"

[[ $# -gt 0 ]] || die "Usage: $(basename ${0}) [command] -s [source] -t [target]"

command="${1}"
shift

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			backup_source_dir=$2
			shift
			[[ -d ${backup_source_dir} ]] || die "${backup_source_dir} is not a valid source photo directory"
			;;
		-t|--target)
			backup_target=$2
			shift
			;;
		*)
			;;
	esac
	shift
done

#********************VERIFY CLI********************
[[ -d "${backup_source_dir}" ]] || die "[-s|--src-dir] is required"
[[ -n "${backup_target}" ]] || die "[-t|--target] is required"

if [[ "${backup_target:0:2}" == "s3" ]]; then
	[[ -n "${S3_BUCKET}" ]] || die "Target is s3, but no S3_BUCKET specified."
	backup_target="${backup_target/s3/s3:\/\/\/${S3_BUCKET}}"
fi

export PASSPHRASE
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

echo "src=${backup_source_dir}"
echo "tgt=${backup_target}"

PREFIX_ARGS="--file-prefix-manifest manifest- --file-prefix-archive archive- --file-prefix-signature signature- "

backup_month() {
	set -e

	local src="${1}"
	local tgt="${2}"
	local year="${3}"
	local month="${4}"
	echo "Begin ${year}-${month} at $(date -Iseconds)"
	duplicity ${PREFIX_ARGS} --name "photos-${year}-${month}" "${src}/${year}/${month}" "${tgt}/${year}/${month}"
	echo "End ${year}-${month} at $(date -Iseconds) ($(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec runtime)"
}

case $command in
	backup)
		make_temp_file jobs && jobs_file=${temp_file}
		make_temp_file lifecycle && lifecycle_file=${temp_file}
		trap "{ rm -f ${jobs_file} ${lifecycle_file} ; }" SIGHUP SIGINT SIGTERM EXIT

		echo '{ "Rules": [' > ${lifecycle_file}
		for year in $(cd ${backup_source_dir} && ls -1rd *); do
			for month in $(seq -w 12 -1 1); do
				if [[ -d "${backup_source_dir}/${year}/${month}" ]]; then
					# Write commands to temp file for later parallel processing.
					# no 'command' means 'full or increment'
					echo "backup_month ${backup_source_dir} ${backup_target} ${year} ${month}" >> ${jobs_file}

					# Create AWS lifecycle rule to move archive files to glacier.
					# This will only be used if the target is AWS.
					cat >> "${lifecycle_file}" <<-RULE
			  		  {
			    		"ID": "${year}-${month} Glacier Archive",
			    		"Prefix": "${year}/${month}/archive",
			    		"Status": "Enabled",
			    		"Transitions": [
			      		  {
			        		"Days": 1,
			        		"StorageClass": "GLACIER"
			      		  }
			    		]
			  		  },
					RULE
				fi
			done
		done
		echo ']}' >> "${lifecycle_file}"

		# Make sure these are available to `parallel` subprocesses
		export PREFIX_ARGS
		export -f backup_month
		cat "${jobs_file}" | parallel --halt 'soon,fail=1' --eta || echo "BACKUP FAILED!" && exit 1

		# This is a hack to remove the last trailing comma from the rule array
		tac "${lifecycle_file}" | sed '2 s/},/}/' | tac > tmp.json
		mv tmp.json "${lifecycle_file}"
		if [[ "${backup_target:0:2}" == "s3" ]]; then
			echo "Updating S3 bucket lifecycle configuration."
			aws s3api put-bucket-lifecycle-configuration --bucket ${S3_BUCKET} --lifecycle-configuration file://${lifecycle_file} 
		fi
		;;
	verify-all|restore-all)
		for dir in $(find ${backup_source_dir}/ -maxdepth 2 -mindepth 2 -type d -printf "%P\n"); do
			duplicity ${PREFIX_ARGS} ${command} ${@} "${backup_target}/${dir}" "${backup_source_dir}/${dir}"
		done
		;;
	verify|restore)
		duplicity ${PREFIX_ARGS} ${command} ${@} "${backup_target}" "${backup_source_dir}"
		;;
	list|list-current-files)
		duplicity ${PREFIX_ARGS} list-current-files ${@} "${backup_target}"
		;;
	*)
		die "Unknown command: ${command}"
		;;
esac

echo "Backup complete in $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
