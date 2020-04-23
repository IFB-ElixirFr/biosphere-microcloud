# Installation of MicroScope NFS Backend

## Introduction

This component is the NFS server for MicroScope.

It is based on [this component](https://nuv.la/module/ifb/devzone/NFS-Frontend-Backend/MonBackEndNFS-v18772-copy/18857)
by S. Delmotte (we use the "secure" version where only some VM can mount the share).

## Parameters
Inputs:
  - `frontend_private_ip`: IP adress of the `frontend` component (connected to `frontend:private_ip`)

Outputs:
  - `is_ready`: indicates when this component is ready

## Technical notes

The code is left in the Applications Workflows part of SlipStream to make easier the changes that S. Delmotte could make in the NFS server component.

We install a NFS server and create shared directory /var/nfsshare. Then, we modify /etc/exports to decide whose client is allowed to access share directory. For the moment, only the frontend client is allowed.
 

## TODO
