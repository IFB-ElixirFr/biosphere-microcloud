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

# Wait for the shared directory /env
ss-display "Waiting master to mount /env dir"
shared_dir_ready=$(ss-get --timeout=800 end_mount)
while [ "$shared_dir_ready" != "true" ]
do
    sleep 60;
    shared_dir_ready=$(ss-get --timeout=800 end_mount)
done

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

#################################
# Slurm Logrotate Configuration #
#################################
cat <<EOF> /etc/logrotate.d/slurm
/var/log/slurm/*.log {
    compress
    missingok
    nocopytruncate
    nocreate
    nodelaycompress
    nomail
    notifempty
    noolddir
    rotate 5
    sharedscripts
    size=5M
    create 640 slurm root
    postrotate
    /etc/init.d/slurm reconfig
    endscript
}
EOF

msg_info "Slave ready"

