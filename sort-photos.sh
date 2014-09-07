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
			src_photo_dir=$2
			shift
			[[ -d ${src_photo_dir} ]] || die "${src_photo_dir} is not a valid source photo directory"
			;;
		-t|--target-dir)
			target_photo_dir=$2
			shift
			[[ -d ${target_photo_dir} ]] || die "${target_photo_dir} is not a valid target photo directory"
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
#TODO [[ -n ${target_photo_dir} ]] || target_photo_dir=~/photos
[[ -n ${src_photo_dir} ]] || die "[-s|--src-dir] is required"
[[ -n ${target_photo_dir} ]] || die "[-t|--target-dir] is required"
[[ ${src_photo_dir} != ${target_photo_dir} ]] || die "--src-dir and --target-dir may not be the same"
echo "Sorting photos from ${src_photo_dir} to ${target_photo_dir}"

#********************Filter photos*************************
echo "Select photos to keep"
echo "Rotate with <>"
echo "Mark for deletion with d"
echo "Press q when finished"
feh_file=${src_photo_dir}/selected.txt
${FEH_CMD} -d -g 800x600 -f ${feh_file} ${src_photo_dir}

#********************SET ASIDE SELECTED PHOTOS***********************
echo "Setting aside selected photos..."
selected_photo_dir=${src_photo_dir}/selected_photos
mkdir ${selected_photo_dir}
while read f; do
	mv -v "${f}" ${selected_photo_dir}
done < ${feh_file}

#********************Filter Videos*************************
echo "Your videos will be played one by one, and you will be asked whether to select each one. Ready?"
pause
# nullglob prevents bash from making a fuss when one of the filetypes isn't present
# however, it can cause problems if you aren't careful (e.g. with `ls *.nomatch`). So we
# unset it at the end of the loop
shopt -s nullglob
for v in *.mov *.MOV *.mp4 *.MP4 *.m4v *.M4V *.mkv *.MKV; do
	if [[ -f ${v} ]]; then
		echo "Found video file ${v}"
		vlc ${v}
		echo "Do you want to keep that video?"
		read keep_vid 
		if [ ${keep_vid:0:1} == "y" ]; then
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
echo "Sorting selected files to ${target_photo_dir}"
${EXIFTOOL_CMD} -ext '*' '-Directory<CreateDate' -d ${target_photo_dir}/%Y-%m ${selected_photo_dir}
[[ $? -eq 0 ]] || die "Failed to organize photos by CreateDate!"

if [ -n "$(ls -A ${selected_photo_dir})" ]; then
	echo "The following files did not have 'CreateDate' exif data. They will be sorted by file modified time"
	ls -A ${selected_photo_dir}
	${EXIFTOOL_CMD} -ext '*' '-Directory<FileModifyDate' -d ${target_photo_dir}/%Y-%m ${selected_photo_dir}
	[[ $? -eq 0 ]] || die "Failed to organize photos by FileModifyDate!"
fi
if [ -n "$(ls -A ${selected_photo_dir})" ]; then
	die "Some files were not sorted! Sort them manually in ${selected_photo_dir}"
fi

#********************CLEAN UP***********************
echo "Sorted all selected photos!"
safe_delete selected.txt
safe_delete ${selected_photo_dir}

if [ -n "$(ls -A ${src_photo_dir})" ]; then
	ls -A ${src_photo_dir}
	echo "The files above were NOT selected or sorted. Are you sure they can be deleted?"
	read is_ok
	if [ ${is_ok:0:1} == "y" ]; then
		safe_delete ${src_photo_dir}
	else
		echo "Did not delete any files in ${src_photo_dir}"
	fi
fi

