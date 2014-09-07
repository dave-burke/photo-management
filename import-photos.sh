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
			mount_point=${2}
			shift
			[[ -d ${mount_point} ]] || die "${mount_point} is not a valid mount point"
			;;
		-s|--src-dir)
			src_photo_dir=$2
			shift
			#Can't verify until after mounting
			;;
		-t|--target-dir)
			target_photo_dir=$2
			shift
			#Defaulted to ${DEFAULT_TARGET_DIR}
			;;
		-p|--preset)
			preset=$2
			shift
			if [ ${preset} == "android-sd" ]; then
				echo "Backing up from Android SD card"
				device=mtp
				mount_point=/media/android
				src_photo_dir=${mount_point}/Card/DCIM
			elif [ ${preset} == "android" ]; then
				echo "Backing up from Android internal storage"
				device=mtp
				mount_point=/media/android
				src_photo_dir=${mount_point}/DCIM
			elif [ ${preset} == "cam" ]; then
				echo "Backing up camera"
				device=/dev/disk/by-label/CAMERA
				mount_point=/media/cam
				src_photo_dir=${mount_point}/DCIM
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
[[ -n "${src_photo_dir}" ]] || die "[-s|--src-dir] is required"
if [ -n "${device}" -a -z "${mount_point}" ]; then
	die "[-m|--mount-point] is required when you specify a [-d|--device]"
fi
if [ -n "${mount_point}" -a -z "${device}" ]; then
	die "[-d|--device] is required when you specify a [-m|--mount-point]"
fi

#********************SET DEFAULTS********************
if [[ -z "${target_photo_dir}" ]]; then
	target_photo_dir=${DEFAULT_TARGET_DIR}
fi

echo "***SUMMARY***"
echo Device: ${device}
echo Mount point: ${mount_point}
echo Source dir: ${src_photo_dir}
echo Target dir: ${target_photo_dir}
echo "*************"

#********************MOUNT DEVICE********************
if [ -n "${device}" ]; then
	echo "Mounting device..."
	if is_mtp ${device} ; then
		${MTP_UTIL} ${mount_point}
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
if [ -d "${src_photo_dir}" ]; then
	echo "Found ${src_photo_dir}"
else
	die "Couldn't find source photo directory on device: ${src_photo_dir}"
fi

#********************CREATE TARGET PHOTO DIRECTORY********************
echo -n "Checking target directory..."
if [ -d "${target_photo_dir}" ]; then
	echo "Found ${target_photo_dir}"
else
	echo -n "Not found..."
	mkdir -pv "${target_photo_dir}"
	if [ ! -d "${target_photo_dir}" ]; then
		die "Couldn't make directory at ${target_photo_dir}"
	fi
fi

#********************COPY AND VERIFY THE PHOTOS********************
echo Copying photos...
${RSYNC_CMD} -av -h --progress --exclude="cache" "${src_photo_dir}/" "${target_photo_dir}"
if [ $? -eq 0 ]; then
	echo "Success!"
	safe_delete ${src_photo_dir}
else
	die "Failed to sync photos!"
fi

#********************UNMOUNT THE DEVICE********************
if [ -n "${device}" ]; then
	echo "Unmounting the device"
	sync ; sleep 2
	if is_mtp ${device} ; then
		fusermount -u "${mount_point}"
	else
		umount -v "${mount_point}"
	fi
fi

echo Done!
