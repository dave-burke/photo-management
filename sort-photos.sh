#!/bin/bash

source $(dirname ${0})/imports.sh

verify_command feh || die "You must have feh installed to select photos"
SELECTION_TOOL=${VERIFIED_COMMAND}
verify_command exiftool || die "You must have exiftool installed to sort photos"
SORT_TOOL=${VERIFIED_COMMAND}

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			srcPhotoDir=$2
			shift
			[[ -d ${srcPhotoDir} ]] || die "${srcPhotoDir} is not a valid source photo directory"
			;;
		-t|--target-dir)
			targetPhotoDir=$2
			shift
			[[ -d ${targetPhotoDir} ]] || die "${targetPhotoDir} is not a valid target photo directory"
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
#TODO [[ -n ${targetPhotoDir} ]] || targetPhotoDir=~/photos
[[ -n ${srcPhotoDir} ]] || die "[-s|--src-dir] is required"
[[ -n ${targetPhotoDir} ]] || die "[-t|--target-dir] is required"
[[ ${srcPhotoDir} != ${targetPhotoDir} ]] || die "--src-dir and --target-dir may not be the same"
echo "Sorting photos from ${srcPhotoDir} to ${targetPhotoDir}"

#********************Filter photos*************************
cd ${srcPhotoDir}
echo "Select photos to keep with ${SELECTION_TOOL}"
echo "Rotate with <>"
echo "Delete with d"
feh_file=selected.txt
#feh -d -g 800x600 -f ${feh_file} ${srcPhotoDir}

#********************SORT SELECTED PHOTOS***********************
echo "Sorting photos to ${targetPhotoDir}"
exit 0

while read f; do
	${SORT_TOOL} -ext '*' --ext CTG '-Directory<CreateDate' -d ${targetPhotoDir}/%Y-%m ${f}
	if [ $? -eq 0 ]; then
		echo "Sorted ${f}!"
		safe_delete ${f}
	else
		die "Failed to organize ${f}!"
	fi
done < ${feh_file}

#********************TRASH UNSELECTED PHOTOS********************
safe_delete ${srcPhotoDir}
