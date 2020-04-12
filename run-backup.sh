#!/bin/bash

set -e

APP_HOME="$(dirname $(realpath ${0}))"
source "${APP_HOME}/common.sh"

function syncTo {
	echo "Attempting to sync to '$(realpath ${1})'"
	if [[ -n "${1}" ]]; then
		echo "Syncing to ${1}"
		${APP_HOME}/sync-photos.sh -t "${1}"
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

${APP_HOME}/backup-photos.sh backup

