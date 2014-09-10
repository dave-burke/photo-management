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
	if command -v kioclient >/dev/null; then
		echo "Trashing ${1}"
		kioclient move "${1}" trash:/
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

