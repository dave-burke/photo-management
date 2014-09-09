#!/bin/bash

verify_command() {
	VERIFIED_COMMAND=""

	__search_description__=$1
	if [[ $# -gt 1 ]]; then
		shift
	fi

	echo -n Searching for ${__search_description__}...
	for f in $@; do
		if command -v $f >/dev/null; then
			echo Found $(command -v $f)
			VERIFIED_COMMAND=${f}
			return 0
		else
			shift
		fi
	done
	return 1
}

safe_delete() {
	if command -v kioclient >/dev/null; then
		echo "Trashing files"
		kioclient move "${1}" trash:/
	else
		echo Okay to delete ${1}?
		read is_ok
		if [ $is_ok == "yes" ]; then
			rm -rfv "${1}"
		else
			echo "Did not delete ${1}"
		fi
	fi
}

is_mtp() {
	if [[ ${1} == "mtp" ]]; then
		return 0
	else
		return 1
	fi
}

is_mounted() {
	if [[ ! -b ${1} ]]; then
		echo "${1} is not a block device!"
		return 1
	fi
	if mount | grep ${1} >/dev/null; then
		return 0
	else
		return 1
	fi
}

die() {
	echo $1
	if [[ -z "$2" ]]; then
		exit 1
	else
		exit $2
	fi
}

pause() {
	echo -n "Press [Enter] to contine..."
	read
}

get_safe_filename() {
	unset SAFE_NAME
	dirname=$(dirname ${1})
	filename=$(basename ${1})

	name=${filename%.*}
	extension="${filename##*.}"

	if [[ "${name}" == "${extension}" ]]; then
		#No periods in the file name. Just use the filename.
		name=${extension}
		extension=""
	else
		extension=".${extension}"
	fi

	i=1

	SAFE_NAME=${dirname}/${name}${extension}
	while [[ -f ${SAFE_NAME} ]]; do
		SAFE_NAME=${dirname}/${name}-$i${extension}
		i=$((i+1))
	done
}

safe_copy() {
	unset sources
	sources[1]=${1}
	target=${2}
	shift 2

	while [ "$1" ]; do
		sources+=${target}
		target=${1}
		shift
	done

	for s in ${sources}; do
		[[ -f ${s} ]] || die "All source items must be files!"
	done
	for s in ${sources}; do
		if [[ -d ${target} ]]; then
			target_file=${target}/$(basename ${s})
		else
			target_file=${target}
		fi
		get_safe_filename ${target_file}
		cp -iv ${s} ${SAFE_NAME}
	done
}

safe_flatten() {
	source_dir=${1}
	target_dir=${2}
	[[ -d ${source_dir} ]] || die "${source_dir} is not a directory"
	[[ -d ${target_dir} ]] || die "${target_dir} is not a directory"
	find ${source_dir} -type f -print0 | while IFS= read -r -d $'\0' f; do
		safe_copy ${f} ${target_dir}
	done
}

