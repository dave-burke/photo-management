#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

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

for i in 0 1 2 3 4; do
	syncTargetVarName=sync_target_${i}
	if [[ -n ${!syncTargetVarName} ]]; then
		syncTarget=${!syncTargetVarName}
		syncTo "${syncTarget}"
	fi
done

year=$(date +%Y)
$(dirname ${0})/backup-photos.sh incr -y ${year} || $(dirname ${0})/backup-photos.sh full -y ${year}

