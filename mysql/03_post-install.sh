#!/bin/sh -xe

########################
# Docker configuration #
########################

# Add ourselves and centos in docker group
usermod -aG docker root
usermod -aG docker centos

# Pull mysql:5.7 image
docker pull mysql:5.7

