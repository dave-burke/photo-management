#!/bin/bash

set -e

APP_HOME="$(dirname $(realpath ${0}))"
source "${APP_HOME}/common.sh"

for i in 0 1 2 3 4; do
	srcDirVarName=import_source_dir_${i}
	if [[ -n ${!srcDirVarName} ]]; then
		srcDir=${!srcDirVarName}
		if [[ -f "${srcDir}/.stfolder" ]]; then
			isSynced="true"
		fi
		${APP_HOME}/import-photos.sh --source-dir ${srcDir}
		if [[ "${isSynced}" == "true" ]]; then
			touch "${srcDir}/.stfolder"
		fi
	fi
done
${APP_HOME}/sort-photos.sh || echo "Not everything was sorted"

