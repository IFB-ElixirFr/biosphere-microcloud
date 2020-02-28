#!/bin/bash

source /scripts/cluster/elasticluster.sh
source /scripts/populate_hosts_with_components_name_and_ips.sh --dry-run
source /scripts/allows_other_to_access_me.sh --dry-run

# Initiate cluster
export USER_NEW="ubuntu"

auto_gen_users
gen_key_for_user $USER_NEW
publish_pubkey
allow_others

populate_hosts_with_components_name_and_ips hostname

initiate_master_cluster
if [ $IP_PARAMETER == "hostname" ]; then
    check_ip
    if [ "$category" == "Deployment" ]; then
        check_ip_slave_for_master
    fi
fi

install_elasticluster
sed -i '/- slurm-drmaa-dev/d' $playbook_dir/roles/slurm-client/tasks/main.yml
install_ansible
config_elasticluster slurm
install_playbooks slurm

ss-display "Start mounting."

# Create shared directory /env between master, slave(s) and frontend
SLIPSTREAM_DIR="/var/tmp/slipstream"
BASE_DIR=biosphere-microcloud
COMPONENT=master
cd ${SLIPSTREAM_DIR}/${BASE_DIR}/${COMPONENT}

mkdir /env

if [ "$category" == "Deployment" ]; then
    node_multiplicity=$(ss-get $SLAVE_NAME:multiplicity)
    if [ "$node_multiplicity" != "0" ]; then
        # NFS_ready function
        NFS_microcloud_ready 
        
        #NFS_mount function
        NFS_microcloud_mount /env
    fi
fi

ss-display "Shared dir /env ready"


###############################
# Install modules environment #
###############################

# Create working directories
AGC_HOME="/env/cns/proj/agc"
AGC_PRODUCTSHOME="${AGC_HOME}/module/products"
AGC_PROFILESHOME="${AGC_HOME}/module/profiles"

mkdir -p ${AGC_HOME}
mkdir -p ${AGC_PRODUCTSHOME}
mkdir -p ${AGC_PROFILESHOME}

IG_HOME="/env/ig/soft/ig/modules"
mkdir -p ${IG_HOME}

# Access agc repository/resources
URL="https://www.genoscope.cns.fr/agc/ftp/MicroCloud"

# Get minimal resources to perform modules
curl --output ${IG_HOME}/.findproductflavor ${URL}/findproductflavor

# Get modules required to run micJBPMwrapper
cd ${SLIPSTREAM_DIR}/${BASE_DIR}/${COMPONENT}
./import_modules.sh ${AGC_PRODUCTSHOME}


################
# Install jBPM #
################

# Create directories
JBPMDirectory="/env/cns/proj/agc/tools/COMMON/JBPMmicroscope"
JBPMResult="/env/cns/proj/agc/Data/Result/JBPMmicroscope"
mkdir -p ${JBPMDirectory}
chmod g+s ${JBPMDirectory}
mkdir -p ${JBPMDirectory}/data/log
mkdir -p ${JBPMDirectory}/lib
mkdir -p ${JBPMDirectory}/bin
mkdir -p ${JBPMDirectory}/jbpmmicroscope
mkdir -p ${JBPMResult}
chmod g+s ${JBPMResult}
mkdir -p ${JBPMResult}/log

# Get jars
curl --output ${JBPMDirectory}/lib/jbpmmicroscope.jar ${URL}/jbpmmicroscope-client-latest.jar
curl --output ${JBPMDirectory}/lib/SystemActorsLauncher.jar ${URL}/SystemActorsLauncher-latest.jar

# Get sql schema to create jbpm database
curl -o ${JBPMDirectory}/JBPM.sql ${URL}/JBPM.sql

# Extract sources and bin from jbpmmicroscope.jar
cd ${JBPMDirectory}/jbpmmicroscope
jar -xf ${JBPMDirectory}/lib/jbpmmicroscope.jar
mv JBPMmicroscope ${JBPMDirectory}/bin/JBPMmicroscope


##################
# Install Tomcat #
##################

ss-display "Install Apache Tomcat Server"

# Download tomcat 9
cd ${JBPMDirectory}
curl -O ${URL}/apache-tomcat-latest.tar.gz
mkdir -p ${JBPMDirectory}/tomcat
tar xf apache-tomcat-latest.tar.gz -C ${JBPMDirectory}/tomcat --strip-components=1

# Create Tomcat User
groupadd tomcat
useradd -s /bin/false -g tomcat -d ${JBPMDirectory}/tomcat tomcat

# Update Permissions
cd ${JBPMDirectory}/tomcat
chgrp -R tomcat ${JBPMDirectory}/tomcat
chmod -R g+r conf
chmod g+x conf
chown -R tomcat webapps/ work/ temp/ logs/

# Download jbpm war into tomcat/webapps dir
curl --output ${JBPMDirectory}/tomcat/webapps/jbpmmicroscope.war ${URL}/jbpmmicroscope-server-latest.war

# Create Tomcat service
JAVA_HOME="/usr/lib/jvm/default-java"

cd /etc/systemd/system
cat <<EOF>tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=${JAVA_HOME}
Environment=CATALINA_PID=${JBPMDirectory}/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=${JBPMDirectory}/tomcat
Environment=CATALINA_BASE=${JBPMDirectory}/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=${JBPMDirectory}/tomcat/bin/startup.sh
ExecStop=${JBPMDirectory}/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start tomcat
ufw allow 8080

# Configure Tomcat Web Management Interface
TOMCAT_USER=$(ss-get tomcat_user)
TOMCAT_PASSWORD=$(ss-get tomcat_password)

cd ${JBPMDirectory}/tomcat/conf

# Create temp file
head -36 tomcat-users.xml>tomcat-users.xml.tmp

cat <<EOF>> tomcat-users.xml.tmp
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<role rolename="admin"/>
<user username=${TOMCAT_USER} password=${TOMCAT_PASSWORD} roles="manager-gui,admin-gui,admin,manager,manager-script,admin-script"/>
</tomcat-users>
EOF

# Delete temp file
mv tomcat-users.xml.tmp tomcat-users.xml

# Udate context.xml
cd ${JBPMDirectory}/tomcat/webapps/manager/META-INF/
cat <<EOF> context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
    allow="\d+\.\d+\.\d+\.\d+" />
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOF


###########################
# Wait for mysql_hostname #
###########################

ss-display "Waiting SQL server to start"

# Get IP adress of MySQL server
MYSQL_HOST=$(ss-get mysql_hostname)
MYSQL_PASS=$(ss-get mysql_root_password)
MYSQL_USER="root"


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
echo "$(ss-get mysql_hostname) mysqlagcdb.genoscope.cns.fr mysqlagcdb" >> ${HOSTS_FILE}


#######################
# Create jbpm profile #
#######################

ss-display "Writting jbpm.profile"

cd ${SLIPSTREAM_DIR}/${BASE_DIR}/${COMPONENT}

cat <<EOF> jbpm.profile
## JBPM PROFILE ##
JBPMDirectory=${JBPMDirectory}
AGC_PRODUCTSHOME=${AGC_PRODUCTSHOME}

# Databases
export MYAGCDB="pkgdb"
export CPDGODB="GO_CPD"
export CPDPUBDB="PUB_CPD"
export PRESTATIONDB="PRESTATIONDB"
export GORESDB="GO_RES"
export NGSDB="UNSEEN"
export EVOLGENODB="EvolGenome2"
export MYRNASEQDB="RNAseq"
export MYAGCMICROCYCDB="microcyc"
export DBWORKFLOW="DBWorkFlow"
export NCBIREFSEQDB="REFSEQDB"
export GENOMEPUBDB="GenomePubDB"

# DB connection
export MYAGCUSER="root"
export MYAGCPASS=${MYSQL_PASS}
export MYAGCHOST=${MYSQL_HOST}
export MYAGCPORT=3306

export MICROSCOPE_DBconnect="mysql -A -N -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST}"
alias mysqlagcdb="mysql -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST}}"

# micJBPMwrapper
export PATH=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/bin:$PATH

export MICROSCOPE_LIB_SCRIPT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/lib/microscope.lib
export MICROSCOPE_PATH_SCRIPT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch
export MICROSCOPE_CONF_SCRIPT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/conf
export MICJBPMWRAPPER_ROOT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch
export MICJBPMWRAPPER_EXEDIR=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/bin
export MICJBPMWRAPPER_LIBDIR=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/lib

# bagsub
export PATH=${AGC_PRODUCTSHOME}:${PATH}

# Tomcat
export JBPM_PROJECT_SRC=${JBPMDirectory}/jbpmmicroscope
export PATH=${JBPM_PROJECT_SRC}/bin:${PATH}

TOMCAT_HOME=${JBPMDirectory}/tomcat
export TOMCAT_HOME
JBPM_PROJECT_HOME=${JBPMDirectory}
export JBPM_PROJECT_HOME

alias tomcat_status='systemctl status tomcat'
alias tomcat_start='systemctl start tomcat'
alias tomcat_restart='systemctl restart tomcat'
alias tomcat_stop='systemctl stop tomcat'
alias tomcat_logs='tail -f -n 100 $TOMCAT_HOME/logs/catalina.out'

# Slurm
export SLURM_CPUS_ON_NODE=4
EOF

# Source jbpm profile before starting tomcat
cp jbpm.profile ${AGC_PROFILESHOME}/jbpm.profile
cd ${AGC_PROFILESHOME}
source jbpm.profile

# Restart tomcat
systemctl restart tomcat

# Enable service
systemctl enable tomcat

# Redirect port
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080


########################
# Create jbpm database #
########################

ss-display "Creating jbpm database"

# Wait for the MySQL server
ss-display "Waiting MySQL server to start"
ss-get --timeout 16000 mysql_is_ready

MYSQL_USER=root
MYSQL_HOST=$(ss-get mysql_hostname)
MYSQL_PASSWORD=$(ss-get mysql_root_password)

# Connection to mysql
mysql_request="mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD}"

# Create jbpm user
JBPM_USER=$(ss-get jbpm_user)
JBPM_PASSWORD=$(ss-get jbpm_password)

$mysql_request -e "CREATE USER '${JBPM_USER}' IDENTIFIED BY '${JBPM_PASSWORD}';"

# Create JBPM database and grant permissions
$mysql_request -e "CREATE DATABASE JBPMmicroscope";
$mysql_request -e "GRANT ALL privileges ON JBPMmicroscope.* TO '${JBPM_USER}'@'%' IDENTIFIED BY '${JBPM_PASSWORD}';"

# Create JBPMmicroscope schema
$mysql_request JBPMmicroscope < ${JBPMDirectory}/JBPM.sql


##############################
# pegasus-mpi-cluster recipe #
##############################

ss-display "Install Pegagus"

cd ${AGC_PRODUCTSHOME}
curl -O ${URL}/pegasus-latest.tar.gz
tar xf pegasus-latest.tar.gz
cd pegasus-4.9.2/src/tools/pegasus-mpi-cluster

# Delete libnuma requirements
sed -i "s|NUMAIF=.*|NUMAIF=|" Makefile
make
make install

# Shared dir is ready
ss-set end_mount true


################################
# Manage /var/mail/ubuntu file #
################################

# The size of /var/mail/ubuntu has been increasing and may cause memory shortage.
cat <<EOF> /etc/logrotate.d/mailubuntu
/var/mail/ubuntu {
    size 10M   # Rotate if the size is >=10MB
    rotate 5   # Keep 5 rotated logs
    notifempty # Do not rotate if empty
    compress   # Compresses rotated logs, default
}
EOF


#################################
# Slurm Logrotate Configuration #
#################################

cat <<EOF> /etc/logrotate.d/slurm
/var/log/slurm/*.log {
    compress
    missingok
    nocopytruncate
    nocreate
    nodelaycompress
    nomail
    notifempty
    noolddir
    rotate 5
    sharedscripts
    size=5M
    create 640 slurm root
    postrotate
    /etc/init.d/slurm reconfig
    endscript
}
EOF


##########################
# Configuration finished #
##########################

msg_info "Master ready"
