#!/bin/sh -xe
################################################################
# Title: import_modules.sh
# Description: This script import modules from
# agc/ftp/MicroCloud to run micJBPMwrapper
# Usage:$ ./import_modules.sh path
# Date: 2020-02-10
################################################################
cd $1

URL=https://www.genoscope.cns.fr/agc/ftp/MicroCloud
curl -o modules.txt ${URL}/modules.txt

while IFS= read -r line; do
    module_name=$(echo $line | cut -d - -f 1)
    wget -O - ${URL}/$line | tar -xzv --transform "s:^[^/]*:${module_name}:"
done < "modules.txt"
