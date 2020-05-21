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

# Trash to ignore
mkdir "test-data/source/.dtrash/"
touch "test-data/source/.dtrash/junk.jpg"
mkdir "test-data/source/.stversions/"
touch "test-data/source/.stversions/old.jpg"
touch "test-data/source/.stfoler"

# Duplicate filenames
touch "test-data/source/duplicate.jpg"
touch "test-data/source/sub dir/duplicate.jpg"
touch "test-data/target/duplicate.jpg"

### TEST

../import-photos.sh -s test-data/source -t test-data/target

### VERIFY

[[ -f "test-data/target/photo1.jpg" ]] || fail_test "'photo1.jpg' was not imported!"
[[ -f "test-data/target/photo 1.jpg" ]] || fail_test "'photo 1.jpg' was not imported!"
[[ -f "test-data/target/photo2.jpg" ]] || fail_test "'photo2.jpg' was not imported!"
[[ -f "test-data/target/video.mpeg" ]] || fail_test "'video.mpeg' was not imported!"
[[ -f "test-data/target/noextension" ]] || fail_test "'noextension' was not imported!"
[[ -f "test-data/target/duplicate.jpg" ]] || fail_test "'duplicate.jpg' was not imported!"
[[ -f "test-data/target/duplicate-1.jpg" ]] || fail_test "'duplicate-1.jpg' was not imported!"
[[ -f "test-data/target/duplicate-2.jpg" ]] || fail_test "'duplicate-2.jpg' was not imported!"
[[ -f "test-data/target/junk.jpg" ]] && fail_test ".dtrash folder was imported"
[[ -f "test-data/target/old.jpg" ]] && fail_test ".stversions folder was imported"
[[ -f "test-data/target/.stfolder" ]] && fail_test ".stfolder was imported"

if [[ "${FAILED}" == true ]]; then
	echo "FAILED ${0}!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

