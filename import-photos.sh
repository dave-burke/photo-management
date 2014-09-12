#!/bin/bash

DEFAULT_TARGET_DIR=/tmp/photos
source "$(dirname $(realpath ${0}))/common.sh"

#********************FUNCTIONS********************
is_mtp() {
	if [[ "${1}" == "mtp" ]]; then
		return 0
	else
		return 1
	fi
}

is_mounted() {
	local dev="$(realpath ${1})"
	if [[ "${dev}" != "${1}" ]]; then
		echo "Device ${1} is actually ${dev}"
	fi
	if [[ ! -b "${dev}" ]]; then
		echo "${dev} is not a block device!"
		return 1
	fi
	if mount | grep "${dev}" >/dev/null; then
		return 0
	else
		return 1
	fi
}

get_safe_filename() {
	unset SAFE_NAME
	local dirname=$(dirname "${1}")
	local filename=$(basename "${1}")

	local name="${filename%.*}"
	local extension="${filename##*.}"

	if [[ "${name}" == "${extension}" ]]; then
		#No periods in the file name. Just use the filename.
		name="${extension}"
		extension=""
	else
		extension=".${extension}"
	fi

	i=1

	SAFE_NAME="${dirname}/${name}${extension}"
	while [[ -f "${SAFE_NAME}" ]]; do
		SAFE_NAME="${dirname}/${name}-$i${extension}"
		i=$((i+1))
	done
}

safe_copy() {
	local sources[1]="${1}"
	local target="${2}"
	shift 2

	while [ "${1}" ]; do
		sources+="${target}"
		target="${1}"
		shift
	done

	local i
	local s
	for i in $(seq 1 ${#sources[@]}); do
		s=${sources[i]}
		[[ -f ${s} ]] || die "Can't copy non-file ${s}"
	done
	for i in $(seq 1 ${#sources[@]}); do
		s=${sources[i]}
		local target_file
		if [[ -d ${target} ]]; then
			target_file="${target}/$(basename "${s}")"
		else
			target_file="${target}"
		fi
		get_safe_filename "${target_file}"
		cp -iv "${s}" "${SAFE_NAME}"
	done
}

safe_flatten() {
	local source_dir="${1}"
	local target_dir="${2}"
	[[ -d ${source_dir} ]] || die "${source_dir} is not a directory"
	[[ -d ${target_dir} ]] || die "${target_dir} is not a directory"
	find "${source_dir}" -type f -print0 | while IFS= read -r -d $'\0' f; do
		safe_copy "${f}" "${target_dir}"
	done
}

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-d|--device)
			device="${2}"
			shift
			if is_mtp "${device}" ; then
				verify_command "MTP tool" simple-mtpfs || die "simple-mtpfs tools is required for mtp devices"
				MTP_UTIL=${VERIFIED_COMMAND}
			elif [[ ! -b "${device}" ]]; then
				die "Could not find block device \"${device}\"!"
			fi
			;;
		-m|--mount-point)
			mount_point="${2}"
			shift
			[[ -d "${mount_point}" ]] || die "${mount_point} is not a valid mount point"
			;;
		-u|--use-sudo)
			use_sudo=true
			;;
		-s|--source-dir)
			src_photo_dir="${2}"
			shift
			#Can't verify until after mounting
			;;
		-t|--target-dir)
			target_photo_dir="${2}"
			shift
			#Defaulted to ${DEFAULT_TARGET_DIR}
			;;
		-*)
			die "unrecognized option: ${1}"
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

#********************MOUNT DEVICE********************
if [ -n "${device}" ]; then
	echo "Mounting device..."
	if is_mtp "${device}" ; then
		${MTP_UTIL} "${mount_point}"
		[[ $? -eq 0 ]] || die "MTP mount failed!"
	else
		if is_mounted "${device}"; then
			echo "${device} is already mounted."
		else
			if ${use_sudo}; then
				current_uid=$(id -u)
				current_gid=$(id -g)
				sudo mount -v -o umask=0022,uid=${current_uid},gid=${current_gid} "${device}" "${mount_point}"
			else
				mount -v "${device}" "${mount_point}"
			fi
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

#********************MOVE THE PHOTOS********************
echo "Copying photos..."
safe_flatten "${src_photo_dir}" "${target_photo_dir}"

echo "Deleting junk..."
rm -v "${target_photo_dir}"/*.CTG

echo "Deleting source files from ${src_photo_dir}..."
safe_delete "${src_photo_dir}"

#********************UNMOUNT THE DEVICE********************
if [ -n "${device}" ]; then
	echo "Unmounting the device"
	sync ; sleep 2
	if is_mtp "${device}" ; then
		fusermount -u "${mount_point}"
	else
		if ${use_sudo}; then
			sudo umount -v "${mount_point}"
		else
			umount -v "${mount_point}"
		fi
	fi
fi

echo Done!
