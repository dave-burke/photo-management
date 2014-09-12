#!/bin/bash

source "$(dirname $(realpath ${0}))/common.sh"

verify_command duplicity || die "duplicity is required for backing up encrypted photos"

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			src_photo_dir=$2
			shift
			[[ -d ${src_photo_dir} ]] || die "${src_photo_dir} is not a valid source photo directory"
			;;
		-t|--target)
			backup_target=$2
			shift
			;;
		-*)
			die "unrecognized option: $1"
			;;
		*)
			break
			;;
	esac
	shift
done

#********************VERIFY CLI********************
[[ -n ${src_photo_dir} ]] || die "[-s|--src-dir] is required"
[[ -n ${backup_target} ]] || die "[-t|--target-dir] is required"

#********************DO BACKUP********************
if [[ "S3" == ${backup_target} || "s3" == ${backup_target} ]]; then
	echo "Backing up to ${src_photo_dir} to Amazon S3"
else
	echo "Backing up ${src_photo_dir} to ${backup_target}"
fi
