#!/bin/bash
source /scripts/cluster/cluster_install.sh
source /scripts/populate_hosts_with_components_name_and_ips.sh --dry-run
source /scripts/allows_other_to_access_me.sh --dry-run

#main
category=$(ss-get ss:category)
if [ "$category" == "Deployment" ]; then
    export USER_NEW="ubuntu"
else
    ss-abort "You need to deploy with a master!!!"
fi

auto_gen_users
publish_pubkey
allow_others

populate_hosts_with_components_name_and_ips hostname

initiate_slave_cluster
if [ $IP_PARAMETER == "hostname" ]; then
    check_ip
    if [ "$category" == "Deployment" ]; then
        check_ip_master_for_slave
    fi
fi

# Create shared directory /env
mkdir /env

# NFS_ready
NFS_microcloud_ready

# NFS_mount /env
NFS_microcloud_mount /var/nfsshare /env

# Source jbpm profile
JBPMDirectory="/env/cns/proj/agc/tools/COMMON/JBPMmicroscope"
source jbpm.profile ${JBPMDirectory}

# pegasus-mpi-cluster: create link to binary
AGC_PRODUCTSHOME="/env/cns/proj/agc/module/products"
cd $AGC_PRODUCTSHOME/pegasus-4.9.2/src/tools/pegasus-mpi-cluster
make install

msg_info "Slave ready."
