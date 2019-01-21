# Installation of MicroScope web frontend

## Introduction

The frontend is based on Apache2, PHP7.1 and phpMyAdmin.

The installation is two-fold:
* first we need to setup some basics: Apache2, PHP7.1 and phpMyAdmin
* after we setup MicroScope.

For the first part, we adapted the procedure described [here](https://www.howtoforge.com/tutorial/centos-lamp-server-apache-mysql-php/) (based on remi repository).
The [epel repository](https://fedoraproject.org/wiki/EPEL) is already installed on parent image.
We also need to install Tcl/TK for password generation.

MicroScope installation is not done yet.

## Parameters

Inputs:
  - `mysql_hostname`: IP address of the `mysql` component (connected to `mysql:hostname`)
  - `nfsserver_hostname`: IP address of the `nfsserver` component (connected to `nfsserver:hostname`)
  - `nfsserver_is_ready`: used to wait for the `nfsserver` component is ready (connected to `nfsserver:is_ready`)
  - `mysql_is_ready`: used to wait for the `mysql` component is ready (connected to `mysql:is_ready`)
  - `mysql_root_password`: used to create database tables and insert data (connected to `mysql:mysql_root_password`)
  
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

### Installation of phpMyAdmin (04_deployment.sh)

We must set the IP address of the MySQL server in the configuration file (hence the presence in `04_deployment.sh`).
The trick is to do it in PHP with an HERE document:
* the basic syntax is multi-line HERE doc with redirection
* `require_once` is used to load the configuration; we can then modify it in PHP
* `var_export` creates a string representing the variable
* we output a PHP file (with standard open tags) redirected in the new file

Care must be taken to not mix PHP and bash strings and variables.

## Aliases to `mysql` component

Some scripts might assume that the DB server is `mysqlagcdb[.genoscope.cns.fr]`.
To ease the deployment of a first version, we modify `/etc/hosts` so that `mysqlagcdb[.genoscope.cns.fr]` leads to `mysql_hostname`.

This is a bad practice as such programs should be fixed.

## Connection to NFS server (04_deployment.sh)

`nfsserver` needs the private IP address of this component to add it to the NFS configuration.
It waits on `ip_local`.
In return, we need to wait for `nfssserver` to mount the `data` volume.
It waits on `nfsserver_is_ready`.

We set `ip_local` at the very beginning of `04_deployment.sh` to give time to `nfsserver`.
We wait on `nfsserver_is_ready` after having done almost all configuration.

## MicroScope installation (04_deployment.sh)

First, we wrote a script `microscopeRelease.py` to create a tar archive `microcloud.tar.gz` with all necessary items to install MicroScope. Then, we import the latest version of this archive. Once, the archive is uncompressed, the script `install_microscope.sh` is used to create the databases, insert the data, and to copy web code.

## Copy Oid data (04_deployment.sh)

Secondly, we wrote another script `microscopeCopyOid.py` to create a tar archive `microscope_31.tar.gz` that contains minimal data set for a specific Oid. Then, data are inserted in databases with the script `import_Oid.sh`. 

## TODO

Important:
* Apache error doc (needed for MicroScope)
* MicroScope installation (import_Oid.sh)

Security:
* Use parameter for mysql password
* Use a non-root mysql user

Things to consider:
* Remove the alias to `mysql` component
* Better generation of certificates
* Installation with SELinux
