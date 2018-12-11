#!/bin/bash -xe

# Create directory mount
mkdir /data

# Stop Apache
systemctl stop httpd

# Enable Apache
systemctl enable httpd

# Install phpMyAdmin (we ignore IUS repository here)
yum install -y --disablerepo=ius phpMyAdmin

