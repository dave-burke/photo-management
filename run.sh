#!/bin/bash

set -e

$(dirname ${0})/import-photos.sh
$(dirname ${0})/pick-photos.sh
$(dirname ${0})/sort-photos.sh
$(dirname ${0})/backup-photos.sh incr -y 2016 || $(dirname ${0})/backup-photos.sh full -y 2016

