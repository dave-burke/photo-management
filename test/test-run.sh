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

mkdir -pv "test-data/inbox"
cp -arv samples/* "test-data/inbox"

### TEST

export PHOTO_MGMT_CONFIG=test.cfg
../run.sh

### VERIFY

if ! ls "test-data/backup/2016" | grep -q "archive"; then
	fail_test "photos didn't get backed up!"
fi

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

