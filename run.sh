#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

for i in 0 1 2 3 4; do
	srcDirVarName=import_source_dir_${i}
	if [[ -n ${!srcDirVarName} ]]; then
		srcDir=${!srcDirVarName}
		if [[ -f "${srcDir}/.stfolder" ]]; then
			isSynced="true"
		fi
		$(dirname ${0})/import-photos.sh --source-dir ${srcDir}
		if [[ "${isSynced}" == "true" ]]; then
			touch "${srcDir}/.stfolder"
		fi
	fi
done
$(dirname ${0})/sort-photos.sh || echo "Not everything was sorted"

