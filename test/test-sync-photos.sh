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

mkdir -pv "test-data/source/sub dir" "test-data/target"

# Happy path
touch "test-data/source/photo1.jpg"

# File with spaces
touch "test-data/source/photo 1.jpg"

# Directory with spaces
touch "test-data/source/sub dir/photo2.jpg"

# Long extension
touch "test-data/source/video.mpeg"

# No extension
touch "test-data/source/noextension"

### TEST

# Dry run
../sync-photos.sh -s test-data/source -t test-data/target -n

(echo $(find test-data -type d -empty) | grep -q target) || fail_test "Photos were copied with the n command"

# Create junk in target dir
touch "test-data/target/junk.jpg"

# Sync
../sync-photos.sh -s test-data/source -t test-data/target

# Delete source
rm -rfv test-data/source/*

# Reverse
../sync-photos.sh -s test-data/source -t test-data/target -r

### VERIFY

[[ -f "test-data/source/photo1.jpg" ]] || fail_test "'photo1.jpg' was not synced!"
[[ -f "test-data/source/photo 1.jpg" ]] || fail_test "'photo 1.jpg' was not synced!"
[[ -f "test-data/source/sub dir/photo2.jpg" ]] || fail_test "'photo2.jpg' was not synced!"
[[ -f "test-data/source/video.mpeg" ]] || fail_test "'video.mpeg' was not synced!"
[[ -f "test-data/source/noextension" ]] || fail_test "'noextension' was not synced!"
[[ ! -f "test-data/source/junk.jpg" ]] || fail_test "'junk.jpg' was not deleted!"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

