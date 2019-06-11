#!/bin/sh -xe

####################
# Configure Apache #
####################

ss-display "Configuring Apache"

# Create self-signed certificate.
# Adapted from https://doc.ubuntu-fr.org/tutoriel/comment_creer_un_certificat_ssl.
# The file names are the ones used in the default HTTPS configuration for Apache (/etc/httpd/conf.d/ssl.conf).
# Note that CentOS come with scripts to help here (see /etc/ssl/certs/) but I haven't found a way to use them non-interactively.
# The solution here is probably Expect.
# Note that IP is not needed.
IP=$(ss-get hostname)
KEY=/etc/pki/tls/private/localhost.key
CSR=/etc/pki/tls/certs/localhost.csr
CERT=/etc/pki/tls/certs/localhost.crt
openssl genrsa -out ${KEY} 2048
openssl req -new -key ${KEY} -out ${CSR} -subj "/OU=Domain Control Validated/CN=${IP}"
openssl x509 -req -days 365 -in ${CSR} -signkey ${KEY} -out ${CERT}

# Create test page
cat << EOF > /var/www/html/index.php
<?php phpinfo() ?>
EOF

###########################
# Wait for mysql_hostname #
###########################

ss-display "Waiting SQL server to start"

# Get IP adress of MySQL server
mysql_hostname=$(ss-get mysql_hostname)

#########################
# Configure phpMyAdmin  #
# (uses mysql_hostname) #
#########################

ss-display "Configuring phpMyAdmin"

# Backup configuration file
phpmyadmin_config_file=/etc/phpMyAdmin/config.inc.php
mv ${phpmyadmin_config_file} ${phpmyadmin_config_file}.orig

# Modify configuration file in PHP ('cause we are nuts)
# Shell variables inside '${var}' are expanded
# PHP variables must start with \$ 
cat <<EOF | php > ${phpmyadmin_config_file}
<?php
# Load configuration
require_once('${phpmyadmin_config_file}.orig');
# Modify it
\$cfg['Servers'][1]['host']='${mysql_hostname}';
# Dump it in a valid PHP file
\$cfg_text = var_export(\$cfg, \$return=true);
echo("<?php\n");
echo('\$cfg = '); # Simple quotes here otherwise bash substitutes ${cfg} which is null in bash (\$ is needed otherwise PHP substitutes $cfg)
echo(\$cfg_text . ";\n"); # \$ is needed otherwise bash substitutes ${cfg_text} which is null in bash
echo("?>");
?>
EOF

# Set rights on file
chmod 0644 ${phpmyadmin_config_file}

# Backup Apache configuration file for phpMyAdmin
phpmyadmin_apache_file=/etc/httpd/conf.d/phpMyAdmin.conf
cp -p ${phpmyadmin_apache_file} ${phpmyadmin_apache_file}.orig

# Change Apache configuration file for phpMyAdmin
sed -i '16,19d' $phpmyadmin_apache_file
sed -i '16iRequire all granted' $phpmyadmin_apache_file

########################################
# Configure aliases to mysql component #
# (uses mysql_hostname)                #
########################################

ss-display "Adding aliases to mysql component"

HOSTS_FILE=/etc/hosts

# Save /etc/hosts
if [ -e ${HOSTS_FILE} ]
then
  cp -p ${HOSTS_FILE} ${HOSTS_FILE}.orig
fi

# Add mysql_hostname to /etc/hosts
echo "${mysql_hostname} mysqlagcdb.genoscope.cns.fr mysqlagcdb" >> ${HOSTS_FILE}

##############################################
# Mount volumes (we do it here to wait less) #
##############################################

# Wait for the NFS server
ss-display "Waiting NFS server to start"
ss-get --timeout 32000 nfsserver_is_ready

# Get NFS server adress
ipserver=`ss-get nfsserver_hostname`

# Mount the volume
ss-display "Mounting /data"
mount $ipserver:/var/nfsshare /data

######################
# Install MicroScope #
######################

ss-display "Installation of MicroScope"

# Wait for the MySQL server
ss-display "Waiting MySQL server to start"
ss-get --timeout 16000 mysql_is_ready

# Get latest MicroScope code
curl -o microcloud.tar.gz https://www.genoscope.cns.fr/agc/ftp/MicroCloud/microcloud-latest.tar.gz
tar -xvf microcloud.tar.gz

dirname=microcloud
Oid="31"
mysql_user=root
mysql_root_password=$(ss-get mysql_root_password)

./install_microscope.sh ${dirname} ${mysql_hostname} ${mysql_user} ${mysql_root_password}
./import_Oid.sh ${dirname} ${Oid} ${mysql_hostname} ${mysql_user} ${mysql_root_password}

##########################
# Configuration finished #
##########################

ss-display "Configuration finished"

# Start Apache
systemctl start httpd

# Add entry points (HTTP and HTTPS)
old_url_service=$(ss-get url.service)
# genostack cloud use private IPs
if [ "$(ss-get cloudservice)" == "ifb-genouest-genostack" ]
then
  URL=openstack-${IP//\./-}.genouest.org
else
  URL=${IP}
fi
new_url_service=${old_url_service},http://${URL},https://${URL}
ss-set url.service ${new_url_service}

# We are ready
ss-set is_ready true
ss-display "Frontend ready"

