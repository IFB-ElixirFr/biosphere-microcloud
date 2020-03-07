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
    if [ "${module_name}" = "bagsub" ]; then
        sed -i 's/ulimit -u 16384 ; ulimit -n 16384 ; \\\\//' bagsub/linux-noarch/bin/bagsub
        sed -i "s|BAGSUB_MPIRUN_OPTIONS='--mca orte_base_help_aggregate 0 --display-allocation'|BAGSUB_MPIRUN_OPTIONS='--allow-run-as-root --mca orte_base_help_aggregate 0 --display-allocation'|" bagsub/linux-noarch/bin/bagsub
    fi
done < "modules.txt"
