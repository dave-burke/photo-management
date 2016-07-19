#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

$(dirname ${0})/import-photos.sh
$(dirname ${0})/pick-photos.sh
$(dirname ${0})/sort-photos.sh

function syncTo {
	echo "Attempting to sync to '$(realpath ${1})'"
	if [[ -n "${1}" ]]; then
		echo "Syncing to ${1}"
		$(dirname ${0})/sync-photos.sh -t "${1}"
		return 0
	else
		return 1
	fi
}

# More can be added as needed here and in the cfg file.
syncTo "${sync_target_0}" || echo "target 0 is not defined"
syncTo "${sync_target_1}" || echo "target 1 is not defined"

$(dirname ${0})/backup-photos.sh incr -y 2016 || $(dirname ${0})/backup-photos.sh full -y 2016

