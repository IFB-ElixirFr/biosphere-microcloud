#!/bin/bash -xe
# Secure sharing, clients are only allowed one by one
EXPORT_DIR="/var/nfsshare"
EXPORTS_FILE="/etc/exports"

ss-display "Exporting NFS share of $EXPORT_DIR..."

IP_FRONTEND=`ss-get --timeout 800 frontend_private_ip`
echo "${EXPORT_DIR} ${IP_FRONTEND}(rw,sync,no_root_squash,no_all_squash)" >> ${EXPORTS_FILE}

IP_BACKEND=`ss-get --timeout 800 mysql_private_ip`
echo "${EXPORT_DIR} ${IP_BACKEND}(rw,sync,no_root_squash,no_all_squash)" >> ${EXPORTS_FILE}

IP_MASTER=$(ss-get --timeout 800 master_private_ip)
echo "${EXPORT_DIR} ${IP_MASTER}(rw,sync,no_root_squash,no_all_squash)" >> ${EXPORTS_FILE}

SLAVE_NAME=$(ss-get slave_nodename)
IP_PARAMETER="hostname"

for (( i=1; i <= $(ss-get ${SLAVE_NAME}:multiplicity); i++ )); do
    NODE_HOST=$(ss-get ${SLAVE_NAME}.${i}:${IP_PARAMETER})
    echo -ne "${EXPORT_DIR} ${NODE_HOST}(rw,sync,no_root_squash,no_all_squash)\n" >> ${EXPORTS_FILE}
done
echo "" >> ${EXPORTS_FILE} # last for a newline

# all clients are allowed: unsecured solution
#echo "${EXPORT_DIR} *(rw,sync,no_root_squash,no_all_squash)" > ${EXPORTS_FILE}

ss-display "${EXPORT_DIR} is exported."

systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap

systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap

ss-set is_ready true
ss-display "NFS server ready"

