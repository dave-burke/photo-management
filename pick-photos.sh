#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

verify_command feh || die "You must have feh installed to select photos"
FEH_CMD=${VERIFIED_COMMAND}

verify_command vlc || die "VLC is required for selecting videos"
VLC=${VERIFIED_COMMAND}

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			pick_source_dir="${2}"
			shift
			[[ -d "${pick_source_dir}" ]] || die "${pick_source_dir} is not a valid source photo directory"
			;;
		-t|--target-dir)
			pick_target_dir="${2}"
			shift
			;;
		-f|--favorites-dir)
			fav_photo_dir="${2}"
			shift
			;;
		-n|--no-delete-src)
			no_delete_src="true"
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
[[ -n "${pick_source_dir}" ]] || die "[-s|--src-dir] is required"
[[ -n "${pick_target_dir}" ]] || [[ -n "${fav_photo_dir}" ]] || die "[-t|--target-dir] or [-f|--favorites-dir] is required"

#********************SETUP DIRS********************
if [[ -n "${pick_target_dir}" ]]; then
	if [[ ! -d "${pick_target_dir}" ]]; then
		mkdir --verbose --parents "${pick_target_dir}"
		[[ $? -eq 0 ]] || die "Failed to create target photo dir at ${pick_target_dir}"
	fi
	echo "Sorting photos from ${pick_source_dir} to ${pick_target_dir}"
fi
if [[ -n "${fav_photo_dir}" ]]; then
	if [[ ! -d "${fav_photo_dir}" ]]; then
		mkdir --verbose --parents "${fav_photo_dir}"
		[[ $? -eq 0 ]] || die "Failed to create fav photo dir at ${fav_photo_dir}"
	fi
	echo "Saving favorites in ${fav_photo_dir}"
fi

#********************Filter photos*************************
echo "Select photos to keep"
echo "Rotate with <>"
if [[ -d "${fav_photo_dir}" ]]; then
	echo "Save as favorite with s"
fi
if [[ -d "${pick_target_dir}" ]]; then
	echo "Mark for deletion with d"
fi
echo "Press q when finished"
echo "Please wait while feh preloads the files to remove incompatible formats..."
feh_file="${pick_source_dir}/selected.txt"
${FEH_CMD} --preload --draw-filename --geometry 800x600 --filelist "${feh_file}" "${pick_source_dir}"

#********************Filter Videos*************************
if [[ -d "${pick_target_dir}" ]]; then
	echo "Your videos will be played one by one, and you will be asked whether to select each one. Ready?"
	pause
	# nullglob prevents bash from making a fuss when one of the filetypes isn't present
	# however, it can cause problems if you aren't careful (e.g. with `ls *.nomatch`). So we
	# unset it at the end of the loop
	shopt -s nullglob
	for v in ${pick_source_dir}/*.mov \
			${pick_source_dir}/*.MOV \
			${pick_source_dir}/*.mp4 \
			${pick_source_dir}/*.MP4 \
			${pick_source_dir}/*.m4v \
			${pick_source_dir}/*.M4V \
			${pick_source_dir}/*.mkv \
			${pick_source_dir}/*.MKV; do
		if [[ -f "${v}" ]]; then
			v=$(realpath "${v}")
			echo "Found video file ${v}"
			vlc "${v}"
			echo "Do you want to keep that video?"
			read keep_vid 
			if [ ${keep_vid:0:1} == "y" ]; then
				echo "Selected ${v}"
				echo "${v}" >> "${feh_file}"
			else
				echo "Did not select ${v}"
			fi
		else
			echo "${v} is not a video file"
		fi
	done
	shopt -u nullglob
fi

#********************MOVE FAVORITES****************************
if [[ -d "${fav_photo_dir}" ]]; then
	echo "Moving favorite photos..."
	mv -v feh_* ${fav_photo_dir} || echo "No favorites found!"
fi

#********************MOVE SELECTED FILES***********************
if [[ -d "${pick_target_dir}" ]]; then
	echo "Moving selected media..."
	while read f; do
		mv -v "${f}" "${pick_target_dir}"
	done < "${feh_file}"
	safe_delete "${feh_file}"

	if [ -n "$(ls -A "${pick_source_dir}")" ]; then
		ls -A "${pick_source_dir}"
		echo "The files above were NOT selected."
		if [[ -z "${no_delete_src}" ]]; then
			pause
			safe_delete "${pick_source_dir}"
		fi
	fi
else
	safe_delete "${feh_file}"
fi

