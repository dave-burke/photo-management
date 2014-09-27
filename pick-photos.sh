#!/bin/bash

source "$(dirname $(realpath ${0}))/common.sh"

verify_command feh || die "You must have feh installed to select photos"
FEH_CMD=${VERIFIED_COMMAND}

verify_command vlc || die "VLC is required for selecting videos"
VLC=${VERIFIED_COMMAND}

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
echo "Sorting photos from ${src_photo_dir} to ${target_photo_dir}"

if [[ ! -d "${target_photo_dir}" ]]; then
	mkdir --verbose --parents "${target_photo_dir}"
	[[ $? -eq 0 ]] || die "Failed to create target photo dir at ${target_photo_dir}"
fi

#********************Filter photos*************************
echo "Select photos to keep"
echo "Rotate with <>"
echo "Mark for deletion with d"
echo "Press q when finished"
echo "Please wait while feh preloads the files to remove incompatible formats..."
feh_file="${src_photo_dir}/selected.txt"
${FEH_CMD} --preload --draw-filename --geometry 800x600 --filelist "${feh_file}" "${src_photo_dir}"

#********************Filter Videos*************************
echo "Your videos will be played one by one, and you will be asked whether to select each one. Ready?"
pause
# nullglob prevents bash from making a fuss when one of the filetypes isn't present
# however, it can cause problems if you aren't careful (e.g. with `ls *.nomatch`). So we
# unset it at the end of the loop
shopt -s nullglob
for v in ${src_photo_dir}/*.mov \
		${src_photo_dir}/*.MOV \
		${src_photo_dir}/*.mp4 \
		${src_photo_dir}/*.MP4 \
		${src_photo_dir}/*.m4v \
		${src_photo_dir}/*.M4V \
		${src_photo_dir}/*.mkv \
		${src_photo_dir}/*.MKV; do
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

#********************SET ASIDE SELECTED FILES***********************
echo "Moving selected photos..."
while read f; do
	mv -v "${f}" "${target_photo_dir}"
done < "${feh_file}"
safe_delete "${feh_file}"

if [ -n "$(ls -A "${src_photo_dir}")" ]; then
	ls -A "${src_photo_dir}"
	echo "The files above were NOT selected or sorted. Are you sure they can be deleted?"
	read is_ok
	if [ "${is_ok:0:1}" == "y" ]; then
		safe_delete "${src_photo_dir}"
	else
		echo "Did not delete any files in ${src_photo_dir}"
	fi
fi

