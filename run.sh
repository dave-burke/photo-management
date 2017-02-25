#!/bin/bash

set -e

source "$(dirname $(realpath ${0}))/common.sh"

$(dirname ${0})/import-photos.sh
$(dirname ${0})/pick-photos.sh
$(dirname ${0})/sort-photos.sh
$(dirname ${0})/run-backup.sh

