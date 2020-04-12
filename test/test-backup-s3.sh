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

mkdir -pv "test-data/source/1901/"{01,02,03} "test-data/target"
mkdir -pv "test-data/source/1900/04" "test-data/target"

touch test-data/source/1901/01/jan1.txt
touch test-data/source/1901/01/jan2.txt
touch test-data/source/1901/01/jan3.txt
touch test-data/source/1901/02/feb1.txt
touch test-data/source/1901/02/feb2.txt
touch test-data/source/1901/03/mar1.txt
touch test-data/source/1900/04/may1.txt

### TEST INITIAL

../backup-photos.sh backup -s "test-data/source" -t "s3"

### VERIFY

../backup-photos.sh verify -s "test-data/source" -t "s3" || fail_test "Verify returned non-zero"
../backup-photos.sh list -t "s3/1901/01" || fail_test "List returned non-zero"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

