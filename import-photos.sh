#!/bin/bash

DEFAULT_TARGET_DIR=/tmp/photos
source $(dirname ${0})/common.sh

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-d|--device)
			device=${2}
			shift
			if is_mtp ${device} ; then
				verify_command "MTP tool" simple-mtpfs || die "simple-mtpfs tools is required for mtp devices"
				MTP_UTIL=${VERIFIED_COMMAND}
			elif [[ ! -b ${device} ]]; then
				die "Could not find block device \"${device}\"!"
			fi
			;;
		-m|--mount-point)
			mountPoint=${2}
			shift
			[[ ! -d ${mountPoint} ]] || die "${mountPoint} is not a valid mount point"
			;;
		-s|--src-dir)
			srcPhotoDir=$2
			shift
			#Can't verify until after mounting
			;;
		-t|--target-dir)
			targetPhotoDir=$2
			shift
			#Defaulted to ${DEFAULT_TARGET_DIR}
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

#********************VERIFY CLI********************
[[ -n ${device} ]] || die "[-d|--device] is required"

#********************SET DEFAULTS********************
if [[ -z ${targetPhotoDir} ]]; then
	targetPhotoDir=${DEFAULT_TARGET_DIR}
fi

echo "***SUMMARY***"
echo Device: ${device}
echo Mount point: ${mountPoint}
echo Source dir: ${srcPhotoDir}
echo Temp dir: ${tmpPhotoDir}
echo Target dir: ${targetPhotoDir}
echo "*************"

exit 0

#********************MOUNT DEVICE********************
if [ ! -d "${srcPhotoDir}" ]; then #only mount if it's not already done
	if is_mtp ${device} ; then
		${MTP_UTIL} ${mountPoint}
	else
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

#********************UNMOUNT THE DEVICE********************
sync ; sleep 2
if is_mtp ${device} ; then
	fusermount -u "${mountPoint}"
else
	umount -v "${mountPoint}"
fi

echo Done!
