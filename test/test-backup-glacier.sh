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
year=2016

### TEST INITIAL

../backup-photos.sh full -s "${src}" -t "${tgt}" -y ${year}
../backup-photos.sh verify -s "${src}" -t "${tgt}" -y ${year}

### TEST UPDATE

initTime=$(date -Is)
rm -v "test-data/target/2016/archive-"*
sleep 2

touch test-data/source/2016/03/mar2.txt
../backup-photos.sh incr -s "${src}" -t "${tgt}" -y ${year}

### VERIFY

initFiles="$(../backup-photos.sh list --time "${initTime}" -t "${tgt}" -y ${year})"
curFiles="$(../backup-photos.sh list -t "${tgt}" -y ${year})"

echo "${initFiles}" | grep -v "mar2" || fail_test "Init files contained updated file"
echo "${curFiles}" | grep "mar2" || fail_test "Current files did not contain updated file"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

