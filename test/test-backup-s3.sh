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

mkdir -pv "test-data/source/2016/01" "test-data/target"
mkdir -pv "test-data/source/2016/02" "test-data/target"
mkdir -pv "test-data/source/2016/03" "test-data/target"
mkdir -pv "test-data/source/2015/04" "test-data/target"

touch test-data/source/2016/01/jan1.txt
touch test-data/source/2016/01/jan2.txt
touch test-data/source/2016/01/jan3.txt
touch test-data/source/2016/02/feb1.txt
touch test-data/source/2016/02/feb2.txt
touch test-data/source/2016/03/mar1.txt
touch test-data/source/2015/04/may1.txt

### TEST INITIAL

../backup-photos.sh -s "test-data/source" -t "s3" -y 2016

### TEST UPDATE

initTime=$(date -Is)
sleep 2

touch test-data/source/2016/03/mar2.txt
../backup-photos.sh -s "test-data/source" -t "s3" -y 2016

### VERIFY

source ../secrets.cfg
../backup-photos.sh -c verify "s3+http://${BUCKET}/2016" "test-data/source/2016" || fail_test "Verify returned non-zero"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

