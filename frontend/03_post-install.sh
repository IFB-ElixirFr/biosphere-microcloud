#!/bin/bash -xe

# Create directory mount
mkdir /data

# Stop Apache
systemctl stop httpd

# Enable Apache
systemctl enable httpd

