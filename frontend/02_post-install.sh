#!/bin/bash -xe

function ss-display {
    $(which ss-display) "$1" || echo "$1"
}

# Stop Apache
systemctl stop httpd

# Enable Apache
systemctl enable httpd

ss-display "Creating certificate"

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

ss-display "Creating test page"

cat << EOF > /var/www/html/index.php
<?php phpinfo() ?>
EOF

ss-display "Configuring phpMyAdmin"

# Get IP adress of MySQL server
mysql_hostname="`ss-get MySQL_hostname`"

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
chmod 0700 ${phpmyadmin_config_file}

# Backup Apache file
phpmyadmin_apache_file=/etc/httpd/conf.d/phpMyAdmin.conf
cp -p ${phpmyadmin_apache_file} ${phpmyadmin_apache_file}.orig

# Change Apache configuration file
sed -i '16,19d' $phpmyadmin_apache_file
sed -i '16iRequire all granted' $phpmyadmin_apache_file

