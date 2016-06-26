#!/bin/bash

source "$(dirname $(realpath ${0}))/common.sh"

verify_command exiftool || die "You must have exiftool installed to sort photos"
EXIFTOOL_CMD=${VERIFIED_COMMAND}

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			src_photo_dir="${2}"
			shift
			[[ -d "${src_photo_dir}" ]] || die "${src_photo_dir} is not a valid source photo directory"
			;;
		-t|--target-dir)
			target_photo_dir="${2}"
			shift
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
[[ -n "${target_photo_dir}" ]] || die "[-t|--target-dir] is required"
[[ "${src_photo_dir}" != "${target_photo_dir}" ]] || die "--src-dir and --target-dir may not be the same"

if [[ ! -d "${target_photo_dir}" ]]; then
	mkdir --verbose --parents "${target_photo_dir}"
	[[ $? -eq 0 ]] || die "Failed to create target photo dir at ${target_photo_dir}"
fi

#********************SORT SELECTED FILES***********************
function sortBy {
	local field=${1}
	echo "Sorting ${src_photo_dir} to ${target_photo_dir} by ${field}"
	${EXIFTOOL_CMD} -ignoreMinorErrors -recurse -preserve -progress -extension '*' "-Directory<${field}" -dateFormat "${target_photo_dir}/%Y/%m" "${src_photo_dir}"
	#[[ $? -eq 0 ]] || die "Failed to organize photos by ${field}!"
	leftovers="$(find "${src_photo_dir}" -type f)"
	if [ -n "${leftovers}" ]; then
		echo "Some files could not be sorted by '${field}'."
		#echo "${leftovers}"
		return 1
	else
		echo "All files sorted"
		return 0
	fi
}

echo "Sorting photos from ${src_photo_dir} to ${target_photo_dir}"
sortBy DateTimeOriginal || sortBy CreateDate || sortBy FileModifyDate || die "Some files were not sorted! Sort them manually in ${src_photo_dir}"

#********************CLEAN UP***********************
echo "Sorted all photos!"
safe_delete "${src_photo_dir}"

