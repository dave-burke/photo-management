#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"
source "$(dirname $(realpath ${0}))/secrets.cfg"

verify_command duplicity || die "duplicity is required for backing up encrypted photos"

minYear=1900
maxYear=2100

#********************PARSE CLI********************
while [ "$1" ]; do
	case $1 in
		-s|--src-dir)
			src_photo_dir=$2
			shift
			[[ -d ${src_photo_dir} ]] || die "${src_photo_dir} is not a valid source photo directory"
			;;
		-t|--target)
			backup_target=$2
			shift
			;;
		-y|--year)
			year=$2
			shift
			;;
		-c|--command)
			command=$2
			shift
			;;
		-*)
			[[ -n "${command}" ]] || die "unrecognized option: $1"
			break
			;;
		*)
			break
			;;
	esac
	shift
done

for p in manifest archive signature; do
	args+=" --file-prefix-$p ${p}- "
done

export PASSPHRASE
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

if [[ -z "$command" ]]; then
	#********************VERIFY CLI********************
	[[ -d "${src_photo_dir}" ]] || die "[-s|--src-dir] is required"
	[[ -n "${backup_target}" ]] || die "[-t|--target-dir] is required"
	[[ -n "${year}" ]] || die "[-y|--year] is required"
	[[ ${year} -ge ${minYear} ]] || die "[-y|--year] must be a sensible year between ${minYear} and ${maxYear}"
	[[ ${year} -le ${maxYear} ]] || die "[-y|--year] must be a sensible year between ${minYear} and ${maxYear}"
	[[ -d "${src_photo_dir}/${year}" ]] || die "No directory for ${year} in ${src_photo_dir}"
	src_photo_dir+="/${year}"

	#********************DO BACKUP********************
	args+="\
		--verbosity info \
		--full-if-older-than 1Y \
		--progress \
		--name photos-${year} \
		"

	if [[ "S3" == ${backup_target} || "s3" == ${backup_target} ]]; then
		backup_target=s3+http://${BUCKET}/${year}
	else
		backup_target="file://${backup_target}/${year}"
	fi

	duplicity ${args} ${src_photo_dir} ${backup_target}
else
	duplicity ${command} ${args} $@
fi

