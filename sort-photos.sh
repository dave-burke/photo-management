#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

verify_command exiftool || die "You must have exiftool installed to sort photos"
EXIFTOOL_CMD=${VERIFIED_COMMAND}

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			sort_source_dir="${2}"
			shift
			[[ -d "${sort_source_dir}" ]] || die "${sort_source_dir} is not a valid source photo directory"
			;;
		-t|--target-dir)
			sort_target_dir="${2}"
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
[[ -n "${sort_source_dir}" ]] || die "[-s|--src-dir] is required"
[[ -n "${sort_target_dir}" ]] || die "[-t|--target-dir] is required"
[[ "${sort_source_dir}" != "${sort_target_dir}" ]] || die "--src-dir and --target-dir may not be the same"

if [[ ! -d "${sort_target_dir}" ]]; then
	mkdir --verbose --parents "${sort_target_dir}"
	[[ $? -eq 0 ]] || die "Failed to create target photo dir at ${sort_target_dir}"
fi

#********************SORT SELECTED FILES***********************
function sortBy {
	local field=${1}
	echo "Sorting ${sort_source_dir} to ${sort_target_dir} by ${field}"
	${EXIFTOOL_CMD} -ignoreMinorErrors -recurse -preserve -progress -extension '*' "-Directory<${field}" -dateFormat "${sort_target_dir}/%Y/%m" "${sort_source_dir}"
	#[[ $? -eq 0 ]] || die "Failed to organize photos by ${field}!"
	leftovers="$(find "${sort_source_dir}" -type f)"
	if [ -n "${leftovers}" ]; then
		echo "Some files could not be sorted by '${field}'."
		#echo "${leftovers}"
		return 1
	else
		echo "All files sorted"
		return 0
	fi
}

echo "Sorting photos from ${sort_source_dir} to ${sort_target_dir}"
sortBy DateTimeOriginal || sortBy CreateDate || sortBy FileModifyDate || die "Some files were not sorted! Sort them manually in ${sort_source_dir}"

#********************CLEAN UP***********************
echo "Sorted all photos!"
safe_delete "${sort_source_dir}"

