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

