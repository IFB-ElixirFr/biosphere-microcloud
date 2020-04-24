#!/bin/bash -xe

source /scripts/cluster/elasticluster.sh
source /scripts/populate_hosts_with_components_name_and_ips.sh --dry-run
source /scripts/allows_other_to_access_me.sh --dry-run

# Main
auto_gen_users
publish_pubkey
allow_others

populate_hosts_with_components_name_and_ips_on_vm_add hostname

ss-set nfsserver_is_ready "false"
if [ "$SLIPSTREAM_SCALING_NODE" == "slave" ]; then
    add_nodes_elasticluster slurm
else
    ss-abort "Only slave can be added"
fi
