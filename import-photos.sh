#!/bin/bash

DEFAULT_TARGET_DIR=/tmp/photos
source $(dirname ${0})/common.sh

verify_command rsync || die "rsync is required for copying mounted images"
RSYNC_CMD=${VERIFIED_COMMAND}

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
[[ -n "${srcPhotoDir}" ]] || die "[-s|--src-dir] is required"
if [ -n "${device}" -a -z "${mountPoint}" ]; then
	die "[-m|--mount-point] is required when you specify a [-d|--device]"
fi
if [ -n "${mountPoint}" -a -z "${device}" ]; then
	die "[-d|--device] is required when you specify a [-m|--mount-point]"
fi

#********************SET DEFAULTS********************
if [[ -z "${targetPhotoDir}" ]]; then
	targetPhotoDir=${DEFAULT_TARGET_DIR}
fi

echo "***SUMMARY***"
echo Device: ${device}
echo Mount point: ${mountPoint}
echo Source dir: ${srcPhotoDir}
echo Target dir: ${targetPhotoDir}
echo "*************"

#********************MOUNT DEVICE********************
if [ -n "${device}" ]; then
	echo "Mounting device..."
	if is_mtp ${device} ; then
		${MTP_UTIL} ${mountPoint}
	else
		if is_mounted ${device}; then
			echo "${device} is already mounted."
		else
			mount -v "${device}"
		fi
	fi
else
	echo "No device to mount."
fi

#********************VERIFY THE PHOTO SOURCE DIRECTORY********************
echo -n "Checking source directory..."
if [ -d "${srcPhotoDir}" ]; then
	echo "Found ${srcPhotoDir}"
else
	die "Couldn't find source photo directory on device: ${srcPhotoDir}"
fi

#********************CREATE TARGET PHOTO DIRECTORY********************
echo -n "Checking target directory..."
if [ -d "${targetPhotoDir}" ]; then
	echo "Found ${targetPhotoDir}"
else
	echo -n "Not found..."
	mkdir -pv "${targetPhotoDir}"
	if [ ! -d "${targetPhotoDir}" ]; then
		die "Couldn't make directory at ${targetPhotoDir}"
	fi
fi

#********************COPY AND VERIFY THE PHOTOS********************
echo Copying photos...
${RSYNC_CMD} -av -h --progress --exclude="cache" "${srcPhotoDir}/" "${targetPhotoDir}"
if [ $? -eq 0 ]; then
	echo "Success!"
	safe_delete ${srcPhotoDir}
else
	die "Failed to sync photos!"
fi

#********************UNMOUNT THE DEVICE********************
if [ -n "${device}" ]; then
	echo "Unmounting the device"
	sync ; sleep 2
	if is_mtp ${device} ; then
		fusermount -u "${mountPoint}"
	else
		umount -v "${mountPoint}"
	fi
fi

echo Done!
