# Installation of MicroScope MySQL Backend

## Introduction

This component is the MySQL server for MicroScope.

The installation of the MySQL server is based is based on official docker images for MySQL.
See [1] and [2] for some documentation.

## Parameters

Outputs:
  - `mysql_root_password`: MySQL root password generated (see below)
  - `is_ready`: indicates when this component is ready

## Technical notes

The MySQL docker is based on `debian:stretch-slim` image (see [2]).

We generate the root password for MySQL with the same command use in the Docker.
This is easier to reuse it in the code.

The MySQL client (`mysql`) is not installed on the server but is installed inside docker.

To install the UDF:
* we need to install some packages; this is done with `apt-get` (since the docker image is based on Ubuntu);
  for security, we remove them and their dependencies after.
* we need to wait that the server is started; we wait as long as possible doing other things;
  we implement a solution close to the ones described in [2] (section "No connections until MySQL init completes");
  note that [3] suggests using `mysqladmin` instead of `mysql`.

## TODO

Important:
* We need a lot of storage

Security:
* Create a non-root user for MySQL (agc)

TODO:
* If we use external storage for MySQL, we can't choose the root password [2] (see section "Usage against an existing database")

# References

* [1] [MySQL documentation - Section 2.5.7 Deploying MySQL on Linux with Docker](https://dev.mysql.com/doc/refman/5.7/en/linux-installation-docker.html)
* [2] [MySQL Official Docker Image](https://hub.docker.com/_/mysql/)
* [3] [MySQL documentation - Section 2.10.3 Testing the Server](https://dev.mysql.com/doc/refman/5.7/en/testing-server.html)

