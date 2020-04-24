# Installation of MicroScope MySQL Backend

## Introduction

This component is the MySQL server for MicroScope.

The installation of the MySQL server is based on official docker images for MySQL.
See [1] and [2] for some documentation.

The server uses MySQL Federated Engine to connect to the permanent VM (see [3]).

Note that creation of users, schema (including federated links) and insertion of data
are performed in `frontend`.

## Parameters

Inputs:
  - `nfsserver_hostname`: IP address of the `nfsserver` component (connected to `nfsserver:hostname`)
  - `nfsserver_is_ready`: used to wait for the `nfsserver` component is ready (connected to `nfsserver:is_ready`)

Outputs:
  - `mysql_root_password`: MySQL root password generated (see below)
  - `is_ready`: indicates when this component is ready

## Technical notes

## Docker

The MySQL docker is based on `debian:stretch-slim` image (see [2]).

The container is installed in `03_post-install.sh`
and started in `04_deployment.sh`.
We use the option `--federated` to activate the Federated Engine.

We generate the root password for MySQL with the command used in the container.
This is easier to reuse it in the code.

The MySQL client (`mysql`) is not installed on the server but is installed inside the container.

## MicroScope UDF

To install the UDF:
* we need to install some packages; this is done with `apt-get` (since the docker image is based on Ubuntu);
  for security, we remove them and their dependencies after.
* we need to wait that the server is started; we wait as long as possible doing other things;
  we implement a solution close to the ones described in [2] (section "No connections until MySQL init completes");
  note that [4] suggests using `mysqladmin` instead of `mysql`.

## TODO

Important:
* We need a lot of storage

TODO:
* If we use external storage for MySQL, we can't choose the root password [2 - section "Usage against an existing database"].

# References

* [1] [MySQL documentation - Section 2.5.7: Deploying MySQL on Linux with Docker](https://dev.mysql.com/doc/refman/5.7/en/linux-installation-docker.html)
* [2] [MySQL Official Docker Image](https://hub.docker.com/_/mysql/)
* [3] [MySQL documentation - Section 15.8: The FEDERATED Storage Engine](https://dev.mysql.com/doc/refman/5.7/en/federated-storage-engine.html)
* [3] [MySQL documentation - Section 2.10.3 Testing the Server](https://dev.mysql.com/doc/refman/5.7/en/testing-server.html)

