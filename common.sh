#!/bin/bash

verify_command() {
	VERIFIED_COMMAND=""

	local search_description="${1}"
	if [[ $# -gt 1 ]]; then
		shift
	fi

	echo -n Searching for ${search_description}...
	for f in $@; do
		if command -v ${f} >/dev/null; then
			echo Found $(command -v ${f})
			VERIFIED_COMMAND=${f}
			return 0
		else
			shift
		fi
	done
	return 1
}

safe_delete() {
	if [[ -b ${1} ]]; then
		echo "${1} is a device and cannot be deleted"
	elif command -v trash >/dev/null; then
		echo "Trashing ${1}"
		if [[ -d "${1}" ]]; then
			if [[ -z "$(ls ${1})" ]]; then
				echo "No files to delete from directory ${1}"
			else
				trash "${1}"/*
			fi
		else
			trash "${1}"
		fi
	elif command -v kioclient >/dev/null; then
		echo "Trashing ${1}"
		if [[ -d "${1}" ]]; then
			if [[ -z "$(ls ${1})" ]]; then
				echo "No files to delete from directory ${1}"
			else
				kioclient move "${1}"/* trash:/
			fi
		else
			kioclient move "${1}" trash:/
		fi
	else
		echo "Okay to delete ${1}?"
		read is_ok
		if [ ${is_ok} == "yes" ]; then
			rm -rfv "${1}"
		else
			echo "Did not delete ${1}"
		fi
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

if [[ -n ${PHOTO_MGMT_CONFIG} ]]; then
	echo "Loading ${PHOTO_MGMT_CONFIG}"
	source "${PHOTO_MGMT_CONFIG}"
elif [[ -n "$(dirname $(realpath ${0}))/config.cfg" ]]; then
	echo "Using default config"
	source "$(dirname $(realpath ${0}))/config.cfg"
fi

