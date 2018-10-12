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

../backup-photos.sh backup -s "test-data/source" -t "file://test-data/target"

### TEST UPDATE

initTime=$(date -Is)
sleep 2

touch test-data/source/2016/03/mar2.txt
../backup-photos.sh backup -s "test-data/source" -t "file://test-data/target"

### VERIFY

../backup-photos.sh verify -s "test-data/source" -t "file://test-data/target" || fail_test "Verify returned non-zero"
initFiles="$(../backup-photos.sh list --time "${initTime}" -t "file://test-data/target/2016/03")"
curFiles="$(../backup-photos.sh list -t "file://test-data/target/2016/03")"

echo "${initFiles}" | grep -v "mar2" || fail_test "Init files contained updated file"
echo "${curFiles}" | grep "mar2" || fail_test "Current files did not contain updated file"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

