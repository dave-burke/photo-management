#!/bin/bash

set -e

### INIT

cd $(dirname ${0})

### CLEAN

rm -rfv test-data

### SETUP

mkdir -pv "test-data/source"
cp -v samples/* "test-data/source"

### TEST

../pick-photos.sh -s "test-data/source" -t "test-data/target" -f "test-data/favorites"

### VERIFY

if command -v tree >/dev/null; then
	tree test-data
else
	ls -A test-data/*
fi

