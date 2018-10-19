#!/bin/bash -xe

# To ease deployment, disable selinux.
# This should be changed in the future.
setenforce 0

# Install and enable remi repository for PHP 7.1
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php71
yum update

