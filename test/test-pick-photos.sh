#!/bin/bash

FAILED=false
fail_test() {
	echo "${1}"
	FAILED=true
}

### INIT

cd $(dirname ${0})

### CLEAN

rm -rf test-data

### SETUP

mkdir -p "test-data/source" "test-data/target" "test-data/favorites"
cp -v samples/* "test-data/source"

### TEST

../pick-photos.sh -s "test-data/source" -t "test-data/target" -f "test-data/favorites"

### VERIFY

if command -v tree >/dev/null; then
	tree test-data
else
	ls -A test-data/*
fi

if [[ "${FAILED}" == true ]]; then
	echo "FAILED!"
	exit 1
else
	echo "SUCCESS!"
	exit 0
fi

