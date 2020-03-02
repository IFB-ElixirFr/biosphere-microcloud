#!/bin/bash -xe
EXPORT_DIR="/var/nfsshare"
mkdir -p ${EXPORT_DIR}
chmod -R 755 ${EXPORT_DIR}
chown nfsnobody:nfsnobody ${EXPORT_DIR}
