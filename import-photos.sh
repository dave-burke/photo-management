#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

#********************FUNCTIONS********************
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
	find "${source_dir}" \
			-name .dtrash -prune -o \
			-name .stversions -prune -o \
			-name .stfolder -prune -o \
			-type f -print0 | while IFS= read -r -d $'\0' f; do
		safe_copy "${f}" "${target_dir}"
	done
}

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-u|--use-sudo)
			use_sudo=true
			;;
		-s|--source-dir)
			import_source_dir="${2}"
			shift
			#Can't verify until after mounting
			;;
		-t|--target-dir)
			import_target_dir="${2}"
			shift
			;;
		-n|--no-delete-src)
			no_delete_src="true"
			;;
		-*)
			die "unrecognized option: ${1}"
			;;
		*)
			die "unrecognized arg: ${1}"
			;;
	esac
	shift
done

#********************VERIFY CLI********************
[[ -n "${import_source_dir}" ]] || die "[-s|--src-dir] is required"

#********************VERIFY THE PHOTO SOURCE DIRECTORY********************
echo -n "Checking source directory..."
if [ -d "${import_source_dir}" ]; then
	echo "Found ${import_source_dir}"
else
	die "Couldn't find source photo directory on device: ${import_source_dir}"
fi

#********************CREATE TARGET PHOTO DIRECTORY********************
echo -n "Checking target directory..."
if [ -d "${import_target_dir}" ]; then
	echo "Found ${import_target_dir}"
else
	echo -n "Not found..."
	mkdir -pv "${import_target_dir}"
	if [ ! -d "${import_target_dir}" ]; then
		die "Couldn't make directory at ${import_target_dir}"
	fi
fi

#********************MOVE THE PHOTOS********************
echo "Copying photos..."
safe_flatten "${import_source_dir}" "${import_target_dir}"

echo "Deleting junk..."
rm -v "${import_target_dir}"/*.CTG || echo "No CTG files"

if [[ -z "${no_delete_src}" ]]; then
	echo "Deleting source files from ${import_source_dir}..."
	safe_delete "${import_source_dir}"
fi

echo Done!
