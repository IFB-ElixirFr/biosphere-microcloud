# NFS Backend

## Introduction

This component is the NFS server for MicroScope.

It is based on [this component](https://nuv.la/module/ifb/devzone/NFS-Frontend-Backend/MonBackEndNFS-v18772-copy/18857)
by S. Delmotte (we use the "secure" version where only some VM can mount the share).

## Parameters

Inputs:
  - `frontend_private_ip`: IP adress of the `frontend` component (connected to `frontend:private_ip`)
  - `mysql_private_ip`: IP adress of the `mysql` component (connected to `mysql:private_ip`)
  - `master_private_ip`: IP adress of the `master` component (connected to `master:ip.ready`)
  - `slave_nodename`: component name of SLURM compute nodes (connected to `slave:nodename`)

Outputs:
  - `is_ready`: indicates when this component is ready

## Technical notes

### Install/Post-install

We install a NFS server and create the shared directory `/var/nfsshare`.

### Deployment

At this step, we add the IP address of authorized clients to `/etc/exports`:
  - the IP given in `frontend_private_ip`, `master_private_ip` and `mysql_private_ip`
  - the IP of SLURM compute nodes: to get them, we query the component whose name is given in `slave_nodename`,
    get the multiplicity (number of instances) and then the IP of each instance.

## TODO

  - how to react to addition/removal of compute nodes ?