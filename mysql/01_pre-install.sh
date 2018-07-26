#!/bin/sh -xe

# To ease deployment, disable selinux.
# This should be changed in the future.
setenforce 0

# Add docker group and add ourselves and centos in
groupadd docker
usermod -aG docker root
usermod -aG docker centos

