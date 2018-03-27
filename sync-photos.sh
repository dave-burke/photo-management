#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

verify_command rsync || die "rsync is required for syncing photos"

args="--partial --progress --delete --force --exclude=.dtrash -rutv"
#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			sync_source_dir=$2
			shift
			[[ -d ${sync_source_dir} ]] || die "${sync_source_dir} is not a valid source photo directory"
			;;
		-t|--target)
			sync_target=$2
			shift
			;;
		-r|--reverse)
			reverse=1
			;;
		*)
			args+=" $1 "
			;;
	esac
	shift
done

#********************VERIFY CLI********************
[[ -d "${sync_source_dir}" ]] || die "[-s|--src-dir] is required"
[[ -n "${sync_target}" ]] || die "[-t|--target] is required"

if [[ reverse -eq 1 ]]; then
	rsync ${args} ${sync_target}/ ${sync_source_dir}
else
	rsync ${args} ${sync_source_dir}/ ${sync_target}
fi

