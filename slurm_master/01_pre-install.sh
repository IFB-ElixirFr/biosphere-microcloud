#!/bin/bash

#sed -i 's/^.*ssh/ssh/g' /home/ubuntu/.ssh/authorized_keys
#sed -i 's/^.*ssh/ssh/g' /root/.ssh/authorized_keys
#sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
#sed -i 's/.*GSSAPIAuthentication.*/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
#sed -i '/UsePAM/a useDNS no' /etc/ssh/sshd_config
#sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
#sed -i 's/.*PermitEmptyPasswords.*/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config
#systemctl restart sshd
apt update

