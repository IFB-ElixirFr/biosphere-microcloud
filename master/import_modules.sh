#!/bin/sh -xe
################################################################
# Title: import_modules.sh
# Description: This script import modules from
# agc/ftp/MicroCloud to run micJBPMwrapper
# Usage:$ ./import_modules.sh path
# Date: 2020-02-10
################################################################
cd $1

URL=https://www.genoscope.cns.fr/agc/ftp/MicroCloud/modules.txt
curl -o "modules.txt" $URL

while IFS= read -r line; do
    curl --output $1/$line https://www.genoscope.cns.fr/agc/ftp/MicroCloud/$line
    tar -xzf $1/$line -C $1
done < "modules.txt"
