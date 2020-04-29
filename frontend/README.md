# Installation of MicroScope web frontend

## Introduction

The frontend is based on Apache2, PHP7.1 and phpMyAdmin.

The installation is two-fold:
* first we need to setup some basics (Apache2, PHP7.1 and phpMyAdmin) and mount the shared directory
* after we setup MicroScope

For the first part, we adapted the procedure described [here](https://www.howtoforge.com/tutorial/centos-lamp-server-apache-mysql-php/) (based on remi repository).
The [epel repository](https://fedoraproject.org/wiki/EPEL) is already installed on parent image.
We also need to install Tcl/TK for password generation.

MicroScope installation involves:
* create MySQL user and schema and inserting data
* insert data from Oid 31 (this is needed because the web doesn't work without data)
* create federated links to the permanent VM

## Parameters

Note: we don't present inputs and outputs inherited from base image.

Inputs:
  - `mysql_hostname`: IP address of the `mysql` component (connected to `mysql:hostname`)
  - `mysql_root_password`: used to create database tables and insert data (connected to `mysql:mysql_root_password`)
  - `mysql_is_ready`: used to wait for the `mysql` component is ready (connected to `mysql:is_ready`)
  - `nfsserver_hostname`: IP address of the `nfsserver` component (connected to `nfsserver:hostname`)
  - `nfsserver_is_ready`: used to wait for the `nfsserver` component is ready (connected to `nfsserver:is_ready`)
  - `permanent_VM_hostname`: IP address of permanent VM (constant: 134.214.33.214)
  - `permanent_VM_mysql_root_password`: MySQL root password for permanent VM (constant)
  - `permanent_VM_port`: Permanent VM port to use (constant: 3306)

Outputs:
  - `private_ip`: the local IP address of this component; this output is set in the parent image
    (due to to a bug in slipstream, we have to declare it in `frontend`)
  - `is_ready`: indicate when this component is ready

## Service URL

The following service URL are defined:

  - `ssh://centos@<IP>`: SSH access
  - `http[s]://<IP>`: start page
  - `http[s]://<IP>/phpMyAdmin` (or `phpmyadmin`): phpMyAdmin

## Technical notes

The base image is [IFB CentOS 7 image](https://nuv.la/module/ifb/examples/images/centos-7-ifb).

### Installation of phpMyAdmin (04_deployment.sh)

We must set the IP address of the MySQL server in the configuration file (hence the presence in `04_deployment.sh`).
The trick is to do it in PHP with an HERE document:
* the basic syntax is multi-line HERE doc with redirection
* `require_once` is used to load the configuration; we can then modify it in PHP
* `var_export` creates a string representing the variable
* we output a PHP file (with standard open tags) redirected in the new file

Care must be taken to not mix PHP and bash strings and variables.

### Aliases to `mysql` component

Some scripts might assume that the DB server is `mysqlagcdb[.genoscope.cns.fr]`.
To ease the deployment of a first version, we modify `/etc/hosts` so that `mysqlagcdb[.genoscope.cns.fr]` leads to `mysql_hostname`.

This is a bad practice as such programs should be fixed.

### Connection to NFS server (04_deployment.sh)

`nfsserver` needs the private IP address of this component to add it to the NFS configuration.
It waits on `ip_local`.
In return, we need to wait for `nfssserver` to mount the `data` volume.
It waits on `nfsserver_is_ready`.

We set `ip_local` at the very beginning of `04_deployment.sh` to give time to `nfsserver`.
We wait on `nfsserver_is_ready` after having done almost all configuration.

### MicroScope installation (04_deployment.sh)

`microscopeRelease.py` is used to create a tar archive `microcloud.tar.gz` with all necessary items to install MicroScope.
Then, the latest version of this archive is imported to frontend component and uncompressed.
`install_microscope.sh` use these uncompressed files to create the databases, insert the data, and copy web code.

### Copy data for a chosen Oid (04_deployment.sh)

`microscopeCopyOid.py` is used to create a tar archive `microscope_31.tar.gz` that contains minimal data set for a specific Oid.
Then, the latest version of this archive is imported to frontend component and data are inserted in backend databases with `import_Oid.sh`.

### Create federated links between the mysql server and the permanent VM (04_deployment.sh)

`create_federated_links.py` create federated tables and server links between permanent VM that contains public data banks and backend component to access these data.

## TODO
Important:
* Apache error doc (needed for MicroScope)

Things to consider:
* Remove the alias to `mysql` component
* Better generation of certificates
* Installation with SELinux
