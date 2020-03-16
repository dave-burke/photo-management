#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"
source "$(dirname $(realpath ${0}))/secrets.cfg"

verify_command duplicity || die "duplicity is required for backing up encrypted photos"

[[ $# -gt 0 ]] || die "Usage: $(basename ${0}) [command] -s [source] -t [target]"

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
		*)
			;;
	esac
	shift
done

#********************VERIFY CLI********************
[[ -d "${backup_source_dir}" ]] || die "[-s|--src-dir] is required"
[[ -n "${backup_target}" ]] || die "[-t|--target] is required"

if [[ "${backup_target:0:2}" == "s3" ]]; then
	[[ -n "${S3_BUCKET}" ]] || die "Target is s3, but no S3_BUCKET specified."
	backup_target="${backup_target/s3/s3+http:\/\/${S3_BUCKET}}"
fi

export PASSPHRASE
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

echo "src=${backup_source_dir}"
echo "tgt=${backup_target}"

function dupli {
	duplicity \
		--file-prefix-manifest manifest- \
		--file-prefix-archive archive- \
		--file-prefix-signature signature- \
		$@
}

case $command in
	backup)
		echo '{ "Rules": [' > lifecycle.json
		for year in $(cd ${backup_source_dir} && ls -1rd *); do
			for month in $(seq -w 12 -1 1); do
				subdir="${year}/${month}"
				if [[ -d "${backup_source_dir}/${subdir}" ]]; then
					nFiles=$(ls -1 ${backup_source_dir}/${subdir} | wc -l)
					# no 'command' means 'full or increment'
					echo "Backing up ${backup_source_dir}/${subdir} to ${backup_target}/${subdir} as photos-${year}-${month}"
					dupli \
						--progress \
						--progress-rate 60 \
						--name "photos-${year}-${month}" ${@} \
						"${backup_source_dir}/${subdir}" "${backup_target}/${subdir}"
					cat >> lifecycle.json <<-RULE
			  		  {
			    		"ID": "${year}-${month} Glacier Archive",
			    		"Prefix": "${year}/${month}/archive",
			    		"Status": "Enabled",
			    		"Transitions": [
			      		  {
			        		"Days": 1,
			        		"StorageClass": "GLACIER"
			      		  }
			    		]
			  		  },
					RULE
				fi
			done
		done
		echo ']}' >> lifecycle.json
		# This is a hack to remove the last trailing comma from the rule array
		tac lifecycle.json | sed '2 s/},/}/' | tac > tmp.json
		mv tmp.json lifecycle.json
		if [[ "${backup_target:0:2}" == "s3" ]]; then
			echo "Updating S3 bucket lifecycle configuration."
			aws s3api put-bucket-lifecycle-configuration --bucket ${S3_BUCKET} --lifecycle-configuration file://lifecycle.json 
		fi
		rm lifecycle.json
		;;
	verify|restore)
		for dir in $(find ${backup_source_dir}/ -maxdepth 2 -mindepth 2 -type d -printf "%P\n"); do
			dupli ${command} ${@} "${backup_target}/${dir}" "${backup_source_dir}/${dir}"
		done
		;;
	list|list-current-files)
		dupli list-current-files ${@} "${backup_target}"
		;;
	*)
		die "Unknown command: ${command}"
		;;
esac

echo "Backup complete in $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
