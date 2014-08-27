#!/bin/bash

# TODO test safe_delete, split into multiple scripts:
# imports.sh (common functions)
# import-photos.sh (move photos from device to tmp dir)
# sort-photos.sh (use feh to pick photos, use exiftool to sort into dated directories)
# backup-photos.sh (to s3)
#********************FUNCTION DECLARATIONS********************
verify_command() {
	VERIFIED_COMMAND=""

	SEARCH_DESCRIPTION=$1
	if [[ $# -gt 1 ]]; then
		shift
	fi

	echo Searching for ${SEARCH_DESCRIPTION}
	for f in $@; do
		if command -v $f >/dev/null; then
			echo Found $(command -v $f)
			VERIFIED_COMMAND=${f}
			return 0
		else
			echo "No ${f}..."
			shift
		fi
	done
	echo "No ${SEARCH_DESCRIPTION} found!"
	return 1
}

safe_delete() {
	if command -v kioclient >/dev/null; then
		echo "Trashing files"
		kioclient move "${1}" trash:/
	else
		echo Okay to delete ${1}?
		read isOk
		if [ $isOk == "yes" ]; then
			rm -rfv "${1}"
		else
			echo "Did not delete ${1}"
		fi
	fi
}

is_mtp() {
	if [[ ${1} == "mtp" ]]; then
		return 0
	else
		return 1
	fi
}

die() {
	echo $1
	if [[ -z $2 ]]; then
		exit 1
	else
		exit $2
	fi
}

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-d|--device)
			device=${2}
			shift
			;;
		-s|--src-dir)
			srcPhotoDir=$2
			shift
			;;
		-t|--target_dir)
			targetPhotoDir=$2
			shift
			if [[ -d ${targetPhotoDir} ]]; then
				echo Target photo dir is ${targetPhotoDir}
			else
				die "${targetPhotoDir} is not a valid target photo directory" 1
			fi
			;;
		-p|--preset)
			preset=$2
			shift
			if [ ${preset} == "android-sd" ]; then
				echo "Backing up from Android SD card"
				device=mtp
				mountPoint=/media/android
				srcPhotoDir=${mountPoint}/Card/DCIM
			elif [ ${preset} == "android" ]; then
				echo "Backing up from Android internal storage"
				device=mtp
				mountPoint=/media/android
				srcPhotoDir=${mountPoint}/DCIM
			elif [ ${preset} == "cam" ]; then
				echo "Backing up camera"
				device=/dev/disk/by-label/CAMERA
				mountPoint=/media/cam
				srcPhotoDir=${mountPoint}/DCIM
			fi
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

#********************SYSTEM CHECK********************

verify_command exiftool || exit 1
verify_command feh || exit 1

# Verify device
if is_mtp ${device} ; then
	verify_command "MTP tool" simple-mtpfs || exit 1
	MTP_UTIL=${VERIFIED_COMMAND}
elif [[ ! -b ${device} ]]; then
	die "Could not find device \"${device}\"!"
fi

# Default target dir if none specified
[[ ! -z ${targetPhotoDir} ]] || targetPhotoDir=~/photos

[[ -d ${targetPhotoDir} ]] || die "No target directory at ${targetPhotoDir}"

# Set tmp photo dir
tmpPhotoDir=/tmp/photos

echo "***SUMMARY***"
echo Device: ${device}
echo Mount point: ${mountPoint}
echo Source dir: ${srcPhotoDir}
echo Temp dir: ${tmpPhotoDir}
echo Target dir: ${targetPhotoDir}
echo "*************"

exit 0

if [ ! -d "${srcPhotoDir}" ]; then #only mount if it's not already done
	if is_mtp ${device} ; then
		${MTP_UTIL} ${mountPoint}
	else
		if [ ! -b ${device} ]; then
			echo "Can't find a device at ${device}"
			exit 1
		fi
		mount -v "${device}"
	fi
fi

#********************VERIFY THE PHOTO SOURCE DIRECTORY********************
if [ ! -d "${srcPhotoDir}" ]; then
	die "Couldn't find source photo directory on device: ${srcPhotoDir}"
fi

#********************CREATE TEMP PHOTO DIRECTORY********************
if [ ! -d "${tmpPhotoDir}" ]; then
	mkdir -v "${tmpPhotoDir}"
	if [ ! -d "${tmpPhotoDir}" ]; then
		die "Couldn't make directory at ${tmpPhotoDir}"
	fi
else
	echo ${tmpPhotoDir} already exists.
fi

#********************COPY AND VERIFY THE PHOTOS********************
echo Copying photos...
rsync -av -h --progress --exclude="cache" "${srcPhotoDir}/" "${tmpPhotoDir}"
if [ $? -eq 0 ]; then
	echo "Success!"
	safe_delete ${srcPhotoDir}
else
	die "Failed to sync photos!"
fi

#********************Filter photos*************************
echo Filter your photos...
echo "Rotate with <>"
echo "Delete with d"
feh_file=kept.txt
feh -d -g 800x600 -f ${feh_file} ${tmpPhotoDir}

#********************Organize photos*********************
echo Organizing photos...
while read f; do
	exiftool -ext '*' --ext CTG '-Directory<CreateDate' -d ${targetPhotoDir}/%Y-%m ${f}
	if [ $? -eq 0 ]; then
		echo "Sorted ${f}!"
		safe_delete ${f}
	else
		die "Failed to organize ${f}!"
	fi
done < ${feh_file}
safe_delete ${tmpPhotoDir}

#********************UNMOUNT THE DEVICE********************
sync ; sleep 2
if is_mtp ${device} ; then
	fusermount -u "${mountPoint}"
else
	umount -v "${mountPoint}"
fi

echo Done!
