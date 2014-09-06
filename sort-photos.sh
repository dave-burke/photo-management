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

#********************Filter Videos*************************
# nullglob prevents bash from making a fuss when one of the filetypes isn't present
# however, it can cause problems if you aren't careful (e.g. `ls *.nomatch`). So we
# unset it at the end of the loop
shopt -s nullglob
for v in *.mov *.MOV *.mp4 *.MP4 *.m4v *.M4V *.mkv *.MKV; do
	if [[ -f ${v} ]]; then
		echo "Found video file ${v}"
		vlc ${v}
		echo "Do you want to keep that video?"
		read keepVid 
		if [ ${keepVid:0:1} == "y" ]; then
			echo "Selected ${v}"
			echo ${v} >> ${feh_file}
		else
			echo "Did not select ${v}"
		fi
	else
		echo "${v} is not a video file"
	fi
done
shopt -u nullglob

#********************SORT SELECTED FILES***********************
echo "Sorting selected files to ${targetPhotoDir}"
${EXIFTOOL_CMD} -ext '*' '-Directory<CreateDate' -d ${targetPhotoDir}/%Y-%m ${selectedPhotoDir}
[[ $? -eq 0 ]] || die "Failed to organize photos by CreateDate!"

if [ -n "$(ls -A ${selectedPhotoDir})" ]; then
	echo "The following files did not have 'CreateDate' exif data. They will be sorted by file modified time"
	ls -A ${selectedPhotoDir}
	${EXIFTOOL_CMD} -ext '*' '-Directory<FileModifyDate' -d ${targetPhotoDir}/%Y-%m ${selectedPhotoDir}
	[[ $? -eq 0 ]] || die "Failed to organize photos by FileModifyDate!"
fi
if [ -n "$(ls -A ${selectedPhotoDir})" ]; then
	die "Some files were not sorted! Sort them manually in ${selectedPhotoDir}"
fi

echo "Sorted all selected photos!"
safe_delete selected.txt
safe_delete ${selectedPhotoDir}

if [ -n "$(ls -A ${srcPhotoDir})" ]; then
	ls -A ${srcPhotoDir}
	echo "The files above were NOT selected or sorted. Are you sure they can be deleted?"
	read isOk
	if [ ${isOk:0:1} == "y" ]; then
		safe_delete ${srcPhotoDir}
	else
		echo "Did not delete any files in ${srcPhotoDir}"
	fi
fi

