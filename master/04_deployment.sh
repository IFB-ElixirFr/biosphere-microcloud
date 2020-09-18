#!/bin/bash -x

# The following steps may change working directory so we save it
CWD=$(pwd)

# Source functions from biosphere-commons
source /scripts/cluster/elasticluster.sh
source /scripts/populate_hosts_with_components_name_and_ips.sh --dry-run
source /scripts/allows_other_to_access_me.sh --dry-run
source ../lib.sh

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

# Disable option e because those scripts might return non 0
set +e
install_elasticluster
sed -i '/- slurm-drmaa-dev/d' $playbook_dir/roles/slurm-client/tasks/main.yml
install_ansible
config_elasticluster slurm
install_playbooks slurm
# Re-enable option e
set -e

# Reset working directory
cd ${CWD}

######################################################################
# Create shared directory /env between master, slave(s) and frontend #
######################################################################

ss-display "Start mounting."

# Create /env dir
mkdir /env

if [ "$category" == "Deployment" ]; then
    node_multiplicity=$(ss-get $SLAVE_NAME:multiplicity)
    if [ "$node_multiplicity" != "0" ]; then
        # Check NFS is ready
        NFS_ready_microcloud

        # NFS_mount /env
        NFS_mount_microcloud /var/nfsshare $(ss-get --timeout=3600 nfsserver_hostname) /env
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
./import_modules.sh ${AGC_PRODUCTSHOME}


##############################
# pegasus-mpi-cluster recipe #
##############################

ss-display "Installing Pegasus"

pushd ${AGC_PRODUCTSHOME}
curl -O ${URL}/pegasus-latest.tar.gz
tar xf pegasus-latest.tar.gz
rm pegasus-latest.tar.gz
cd pegasus-4.9.2/src/tools/pegasus-mpi-cluster
# Delete libnuma requirements
sed -i "s|NUMAIF=.*|NUMAIF=|" Makefile
# Set PEGASUS_HOME (needed for Makefile)
export PEGASUS_HOME=${AGC_PRODUCTSHOME}/pegasus-4.9.2/
make
make install
popd


################
# Install jBPM #
################

# Create directories
JBPM_PROJECT_SRC="/env/cns/proj/agc/tools/COMMON/JBPMmicroscope"
JBPM_PROJECT_HOME="/env/cns/proj/agc/Data/Result/JBPMmicroscope"
TOMCAT_HOME=${JBPM_PROJECT_SRC}/tomcat

./install_jbpm.sh ${URL} ${JBPM_PROJECT_SRC} ${JBPM_PROJECT_HOME} ${TOMCAT_HOME} ${AGC_PRODUCTSHOME}

# Update PATH
MODULES_PATH=${JBPM_PROJECT_SRC}/bin:${AGC_PRODUCTSHOME}/micGenome/unix-noarch/bin:${AGC_PRODUCTSHOME}/micPrestation/unix-noarch/bin:${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/bin:${AGC_PRODUCTSHOME}/AGCScriptToolMic/unix-noarch/bin:${AGC_PRODUCTSHOME}/micDirecton/linux-noarch/bin:${AGC_PRODUCTSHOME}/bagsub/linux-noarch/bin:${JBPM_PROJECT_SRC}/bin:${PEGASUS_HOME}/bin:${PATH}


#############################
# Install micPrestation env #
#############################

# Create directories
mkdir -p ${AGC_HOME}/scratch_microscope/Genome/
mkdir -p /env/cns/wwwext/microscope_data/micpresta_data/


###########################
# Wait for mysql_hostname #
###########################

ss-display "Waiting SQL server to start"

# Get IP adress of MySQL server
MYSQL_HOST=$(ss-get mysql_hostname)
MYSQL_PASSWORD=$(ss-get mysql_root_password)
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


#############################
# Create microcloud profile #
#############################

ss-display "Writting microcloud.profile"

cat <<EOF> ${AGC_PROFILESHOME}/microcloud.profile
## MicroCloud PROFILE ##
JBPM_PROJECT_SRC=${JBPM_PROJECT_SRC}
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
export MYAGCPASS=${MYSQL_PASSWORD}
export MYAGCHOST=${MYSQL_HOST}
export MYAGCPORT=3306

export MICROSCOPE_DBconnect="mysql -A -N -u${MYSQL_USER} -p${MYSQL_PASSWORD} -h${MYSQL_HOST}"
alias mysqlagcdb="mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -h${MYSQL_HOST}"

# Pegasus
export PEGASUS_HOME=${PEGASUS_HOME}

# micJBPMwrapper
export MICROSCOPE_LIB_SCRIPT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/lib/microscope.lib
export MICROSCOPE_PATH_SCRIPT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch
export MICROSCOPE_CONF_SCRIPT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/conf
export MICJBPMWRAPPER_ROOT=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch
export MICJBPMWRAPPER_EXEDIR=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/bin
export MICJBPMWRAPPER_LIBDIR=${AGC_PRODUCTSHOME}/micJBPMwrapper/unix-noarch/lib

# micPrestation
export DATAdirPRESTA=/env/cns/wwwext/microscope_data/micpresta_data/
export WORKdirPRESTA=${AGC_HOME}/scratch_microscope/Genome/
export LOGOUTPRESTA=${AGC_HOME}/scratch_microscope/Genome/
export TAXONOMYDBDIR=${AGC_HOME}/scratch_microscope/Data/TAXONOMYDB

# micGenome
export MICGENOME_ROOT=${AGC_PRODUCTSHOME}/micGenome/unix-noarch
export MICGENOME_EXEDIR=${AGC_PRODUCTSHOME}/micGenome/unix-noarch/bin
export MICGENOME_LIBDIR=${AGC_PRODUCTSHOME}/micGenome/unix-noarch/lib

# Tomcat
export JBPM_PROJECT_SRC=${JBPM_PROJECT_SRC}

TOMCAT_HOME=${TOMCAT_HOME}
export TOMCAT_HOME
JBPM_PROJECT_HOME=${JBPM_PROJECT_HOME}
export JBPM_PROJECT_HOME

alias tomcat_start='${TOMCAT_HOME}/bin/catalina.sh start'
alias tomcat_stop='${TOMCAT_HOME}/bin/catalina.sh stop'
alias tomcat_logs='tail -f -n 100 ${TOMCAT_HOME}/logs/catalina.out'

# Export PATH (modules and tomcat)
export PATH=${MODULES_PATH}

EOF


################
# Start tomcat #
################

# Source profile before starting tomcat
source ${AGC_PROFILESHOME}/microcloud.profile

# Start tomcat
${JBPM_PROJECT_SRC}/tomcat/bin/catalina.sh start

# Allow port and redirect port
ufw allow 8080
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080


########################
# Create jBPM database #
########################

./config_jbpm.sh ${URL} ${JBPM_PROJECT_SRC} ${MYSQL_HOST} ${MYSQL_USER} ${MYSQL_PASSWORD}


################################
# Manage /var/mail/root file #
################################

ss-display "Configure logrotates"

# The size of /var/mail/root has been increasing and may cause memory shortage.
cat <<EOF> /etc/logrotate.d/mailroot
/var/mail/root {
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
