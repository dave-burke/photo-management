#!/bin/bash

set -e

# NOTE This doesn't actually test glacier, it just
# demonstrates how incremental updates work when
# the archive files are unavailable.

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

mkdir -pv "test-data/target"
mkdir -pv "test-data/source/2016/01"
mkdir -pv "test-data/source/2016/02"
mkdir -pv "test-data/source/2016/03"
mkdir -pv "test-data/source/2015/04"

touch test-data/source/2016/01/jan1.txt
touch test-data/source/2016/01/jan2.txt
touch test-data/source/2016/01/jan3.txt
touch test-data/source/2016/02/feb1.txt
touch test-data/source/2016/02/feb2.txt
touch test-data/source/2016/03/mar1.txt
touch test-data/source/2015/04/may1.txt

src="test-data/source"
tgt="file://test-data/target"

### TEST INITIAL

../backup-photos.sh backup -s "${src}" -t "${tgt}"
../backup-photos.sh verify -s "${src}" -t "${tgt}"

### TEST UPDATE

initTime=$(date -Is)
rm -v test-data/target/*/*/archive-*
sleep 2

touch test-data/source/2016/03/mar2.txt
../backup-photos.sh backup -s "${src}" -t "${tgt}"

### VERIFY

initFiles="$(../backup-photos.sh list --time "${initTime}" -t "${tgt}/2016/03")"
curFiles="$(../backup-photos.sh list -t "${tgt}/2016/03")"

echo "${initFiles}" | grep -v "mar2" || fail_test "Init files contained updated file"
echo "${curFiles}" | grep "mar2" || fail_test "Current files did not contain updated file"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

