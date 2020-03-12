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
	backup_target="${backup_target/s3/s3+http:\/\/${S3_BUCKET}}"
fi

export PASSPHRASE
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

echo "src=${backup_source_dir}"
echo "tgt=${backup_target}"

function dupli {
	duplicity \
		--file-prefix-manifest manifest- \
		--file-prefix-archive archive- \
		--file-prefix-signature signature- \
		$@
}

case $command in
	backup)
		for year in $(cd ${backup_source_dir} && ls -1rd *); do
			for month in $(seq -w 12 -1 1); do
				subdir="${year}/${month}"
				if [[ -d "${backup_source_dir}/${subdir}" ]]; then
					nFiles=$(ls -1 ${backup_source_dir}/${subdir} | wc -l)
					# no 'command' means 'full or increment'
					echo "Backing up ${backup_source_dir}/${subdir} to ${backup_target}/${subdir} as photos-${year}-${month}"
					dupli \
						--progress \
						--progress-rate 60 \
						--name "photos-${year}-${month}" ${@} \
						"${backup_source_dir}/${subdir}" "${backup_target}/${subdir}"
				fi
			done
		done
		;;
	verify|restore)
		for dir in $(find ${backup_source_dir}/ -maxdepth 2 -mindepth 2 -type d -printf "%P\n"); do
			dupli ${command} ${@} "${backup_target}/${dir}" "${backup_source_dir}/${dir}"
		done
		;;
	list|list-current-files)
		dupli list-current-files ${@} "${backup_target}"
		;;
	*)
		die "Unknown command: ${command}"
		;;
esac
