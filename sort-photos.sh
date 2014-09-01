#!/bin/bash

source $(dirname ${0})/common.sh

verify_command feh || die "You must have feh installed to select photos"
FEH_CMD=${VERIFIED_COMMAND}

verify_command exiftool || die "You must have exiftool installed to sort photos"
EXIFTOOL_CMD=${VERIFIED_COMMAND}

verify_command vlc || die "VLC is required for selecting videos"
VLC=${VERIFIED_COMMAND}

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
echo "Select photos to keep"
echo "Rotate with <>"
echo "Mark for deletion with d"
echo "Press q when finished"
feh_file=${srcPhotoDir}/selected.txt
${FEH_CMD} -d -g 800x600 -f ${feh_file} ${srcPhotoDir}

#********************SET ASIDE SELECTED PHOTOS***********************
echo "Setting aside selected photos..."
selectedPhotoDir=${srcPhotoDir}/selected_photos
mkdir ${selectedPhotoDir}
while read f; do
	mv -v "${f}" ${selectedPhotoDir}
done < ${feh_file}

#********************SORT SELECTED PHOTOS***********************
echo "Sorting photos to ${targetPhotoDir}"
${EXIFTOOL_CMD} -ext '*' --ext CTG '-Directory<CreateDate' -d ${targetPhotoDir}/%Y-%m ${selectedPhotoDir}
if [ $? -eq 0 ]; then
	echo "Sorted selected photos!"
	if [ -z "$(ls -A ${selectedPhotoDir})" ]; then
		safe_delete ${srcPhotoDir}
	else
		ls -A ${selectedPhotoDir}
		die "Some files were not sorted! Sort them manually in ${selectedPhotoDir}"
	fi
else
	die "Failed to organize selected photos!"
fi

