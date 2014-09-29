#!/bin/bash

### INIT

cd $(dirname ${0})

### CLEAN

rm -rf test-data

### SETUP

mkdir -p "test-data/source" "test-data/target"
cp -arv samples/* "test-data/source"

### TEST

../sort-photos.sh -s "test-data/source" -t "test-data/target"

### VERIFY

if command -v tree >/dev/null; then
	tree test-data
else
	ls -A test-data/*
fi

