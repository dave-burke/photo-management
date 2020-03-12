#!/bin/bash

set -e

FAILED=false
fail_test() {
	echo "${1}"
	FAILED=true
}

### INIT

cd $(dirname ${0})

### CLEAN

rm -rfv test-data

### SETUP

mkdir -pv "test-data/inbox/a"
touch "test-data/inbox/a/.stfolder"
mkdir -pv "test-data/inbox/b"
cp -av samples/t-rex.jpeg "test-data/inbox/a"
cp -av samples/saurischia_1.jpg "test-data/inbox/b"

### TEST

export PHOTO_MGMT_CONFIG=test.cfg
../run.sh
../backup-photos.sh full -y 2010

### VERIFY

[[ -f "test-data/inbox/a/.stfolder" ]] || fail_test ".stfolder file was not retained"
ls "test-data/backup/2010" | grep -q "archive" || fail_test "photos didn't get backed up!"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

