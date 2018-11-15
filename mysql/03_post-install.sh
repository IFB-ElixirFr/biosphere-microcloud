#!/bin/sh -xe

########################
# Docker configuration #
########################

# Add docker group and add ourselves and centos in
usermod -aG docker root
usermod -aG docker centos

# Disable selinux for docker
CONFIG_FILE=/etc/sysconfig/docker
cp -p ${CONFIG_FILE} ${CONFIG_FILE}.orig
cat > ${CONFIG_FILE} << "EOF"
OPTIONS='--log-driver=journald --signature-verification=false'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi
EOF
chmod 0644 ${CONFIG_FILE}

# Start Docker
systemctl start docker

# Pull mysql image
docker pull mysql:5.7

