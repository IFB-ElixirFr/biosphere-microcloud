# biosphere-microcloud

Component recipes for MicroCloud

This repository contains the recipes needed to deploy MicroScope on IFB Biosphere.

## Components & connections

There are currently 3 components on the project:

  - `nfsserver`: this is the NFS server which exposes storage to the network (under `/var/nfsshare`); it is based on [an example](https://nuv.la/module/ifb/devzone/NFS-Frontend-Backend) by S. Delmotte;
  the code is on SlipStream to ease interaction with S. Delmotte; we use the "secure" version where only the `frontend` VM can mount the share
  - `mysql`: this is the MySQL server; the code is in `mysql` (see notes here)
  - `frontend`: this is the web server; the code is in `frontend` (see notes here); phpMyAdmin is installed on it

The `MicroCloud` application instantiates 1 instance of each component (so we sometime speak of VM).

By nature, the frontend is connected to the MySQL server and the NFS server.

                     ____________
                    |            | ip_local
             ------>|  frontend  |--------
             |      |____________|<---   |
             |                       |   |
    hostname |               is_ready|   |
      _______|_____                __|___V______
     |             |              |             |
     |    mysql    |              |  nfsserver  |
     |_____________|              |_____________|


  - `nfsserver` needs the private IP address of this component to add it to the NFS configuration
  - `frontend` needs to wait for `nfsserver` to be ready to mount the share
  - `frontend` needs the IP adress of `mysql` to configure phpMyAdmin

# Technical notes

## VM naming convention

All names are `lowercase_underscore_separated`.

## Input and output ports naming convention

All names are `lowercase_underscore_separated`.

Inputs and variables in script:

  - if an input is supposed to come from another component its name SHOULD begin with the name of the source component;
  for instance the input connected to the `hostname` output of the `mysql` component is `mysql_hostname`
  - if the value of a parameter is read in a variable, the name of the variable SHOULD be the same than the name of the input

Outputs:

  - the entry name SHOULD NOT start with the name of the component
  - each component SHOULD have a `is_ready` output which is set to `true` at the very end of the deployment script


# TODO

  - add some documentation about `nfssserver`
