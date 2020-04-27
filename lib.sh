#!/bin/bash
######################################################################
# Title: lib.sh
# Description: These functions are used to mount NFS shared directory.
# Date: 2020-04-24
######################################################################

#####
# NFS
#####

# This function is copied from biosphere-commnons (NFS_ready)
# with adaptations for MicroCloud.
NFS_ready_microcloud()
{
    ss-get --timeout=3600 nfsserver_is_ready
    nfs_ready=$(ss-get --timeout=3600 nfsserver_is_ready)
    msg_info "Waiting NFS to be ready."
    while [ "$nfs_ready" != "true" ]
    do
        sleep 10;
	nfs_ready=$(ss-get --timeout=3600 nfsserver_is_ready)
    done
}

# This function is copied from biosphere-commnons (NFS_mount)
# with adaptations for MicroCloud.
NFS_mount_microcloud()
{
    if [[ $# -lt 3 ]]; then
        echo "This function expects 3 arguments !"
    else
        SHARED_DIR=$1
        NFSSERVER_HOSTNAME=$2
        MOUNT_DIR=$3
        msg_info "Mount $MOUNT_DIR where shared directory is $SHARED_DIR from $NFSSERVER_HOSTNAME host)."
        if [ ! -d "$MOUNT_DIR" ]; then
            msg_info "$MOUNT_DIR doesn't exist !"
        else
            msg_info "Mounting $MOUNT_DIR..."

            umount $MOUNT_DIR
            mount $NFSSERVER_HOSTNAME:$SHARED_DIR $MOUNT_DIR 2>/tmp/mount_error_message.txt
            ret=$?
            msg_info "$(cat /tmp/mount_error_message.txt)"

            if [ $ret -ne 0 ]; then
                ss-abort "$(cat /tmp/mount_error_message.txt)"
            else
                 msg_info "$MOUNT_DIR is mounted"
            fi
        fi
    fi
}
