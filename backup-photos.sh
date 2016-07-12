#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"
source "$(dirname $(realpath ${0}))/secrets.cfg"

verify_command duplicity || die "duplicity is required for backing up encrypted photos"

minYear=1900
maxYear=2100

command="${1}"
shift

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			backup_source_dir=$2
			shift
			[[ -d ${backup_source_dir} ]] || die "${backup_source_dir} is not a valid source photo directory"
			;;
		-t|--target)
			backup_target=$2
			shift
			;;
		-y|--year)
			year=$2
			shift
			;;
		*)
			args+=" $1 "
			;;
	esac
	shift
done

#********************VERIFY CLI********************
[[ -d "${backup_source_dir}" ]] || die "[-s|--src-dir] is required"
[[ -n "${backup_target}" ]] || die "[-t|--target-dir] is required"
[[ -n "${year}" ]] || die "[-y|--year] is required"
[[ ${year} -ge ${minYear} ]] || die "[-y|--year] must be a sensible year between ${minYear} and ${maxYear}"
[[ ${year} -le ${maxYear} ]] || die "[-y|--year] must be a sensible year between ${minYear} and ${maxYear}"

backup_source_dir+="/${year}"
backup_target+="/${year}"

for p in manifest archive signature; do
	args+=" --file-prefix-$p ${p}- "
done

args+="\
	--verbosity info \
	--progress \
	--name photos-${year} \
	"
	#--dry-run \

export PASSPHRASE
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

echo "command=${command}"
echo "args=${args}"
echo "at=${@}"
echo "src=${backup_source_dir}"
echo "tgt=${backup_target}"

case $command in
	full|incr|increment|incremental)
		duplicity ${command} ${args} ${@} "${backup_source_dir}" "${backup_target}"
		;;
	verify|restore)
		duplicity ${command} ${args} ${@} "${backup_target}" "${backup_source_dir}"
		;;
	list|list-current-files)
		duplicity list-current-files ${args} ${@} "${backup_target}"
		;;
	*)
		die "Unknown command: ${command}"
		;;
esac

