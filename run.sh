#!/bin/bash

set -e

$(dirname ${0})/import-photos.sh
$(dirname ${0})/pick-photos.sh
$(dirname ${0})/sort-photos.sh
$(dirname ${0})/backup-photos.sh -y 2016

