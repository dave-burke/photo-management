#!/bin/bash

set -e

cd $(dirname ${0})

./test-import-photos.sh
./test-sort-photos.sh
./test-sync-photos.sh
./test-backup-local.sh
./test-backup-glacier.sh
./test-run.sh

