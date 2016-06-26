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

mkdir -pv "test-data/source" "test-data/target"
cp -arv samples/* "test-data/source"

### TEST

../sort-photos.sh -s "test-data/source" -t "test-data/target"

### VERIFY

[[ -f "test-data/target/2005/03/London_-_Crystal_Palace_-_Victorian_Dinosaurs_1.jpg" ]] || fail_test "London_-_Crystal_Palace_-_Victorian_Dinosaurs_1.jpg was not sorted!"
[[ -f "test-data/target/2010/04/4521167129_39bc0b7ab6_z.jpg" ]] || fail_test "4521167129_39bc0b7ab6_z.jpg was not sorted!"
[[ -f "test-data/target/2010/10/saurischia_1.jpg" ]] || fail_test "saurischia_1.jpg was not sorted!"
[[ -f "test-data/target/2016/02/6446470849_39efc3002a_z.jpg" ]] || fail_test "6446470849_39efc3002a_z.jpg was not sorted!"
[[ -f "test-data/target/2016/02/t-rex.jpeg" ]] || fail_test "t-rex.jpeg was not sorted!"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

