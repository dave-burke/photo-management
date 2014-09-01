#!/bin/bash

source $(dirname ${0})/common.sh

verify_command duplicity || die "duplicity is required for backing up encrypted photos"

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			srcPhotoDir=$2
			shift
			[[ -d ${srcPhotoDir} ]] || die "${srcPhotoDir} is not a valid source photo directory"
			;;
		-t|--target)
			backupTarget=$2
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
[[ -n ${srcPhotoDir} ]] || die "[-s|--src-dir] is required"
[[ -n ${backupTarget} ]] || die "[-t|--target-dir] is required"

#********************DO BACKUP********************
if [[ "S3" == ${backupTarget} || "s3" == ${backupTarget} ]]; then
	echo "Backing up to ${srcPhotoDir} to Amazon S3"
else
	echo "Backing up ${srcPhotoDir} to ${backupTarget}"
fi
