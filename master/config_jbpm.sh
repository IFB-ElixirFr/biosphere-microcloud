#!/bin/sh -xe
#############################################################################
# Title: config_jbpm.sh
# Description: Create and set up JBPMmicroscope database.
# Usage: ./config_jbpm.sh JBPM_DIRECTORY MYSQL_HOST MYSQL_USER MYSQL_PASSWORD
# Date: 2020-04-23
#############################################################################

JBPM_DIRECTORY=$1
MYSQL_HOST=$2
MYSQL_USER=$3
MYSQL_PASSWORD=$4

ss-display "Creating JBPMmicroscope database"

# Connection to mysql
MYSQL_REQUEST="mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD}"

# Create jbpm user
JBPM_USER=$(ss-get jbpm_user)
JBPM_PASSWORD=$(ss-get jbpm_password)

$MYSQL_REQUEST -e "CREATE USER '${JBPM_USER}' IDENTIFIED BY '${JBPM_PASSWORD}';"

# Create JBPM database and grant permissions
$MYSQL_REQUEST -e "CREATE DATABASE JBPMmicroscope";
$MYSQL_REQUEST -e "GRANT ALL privileges ON JBPMmicroscope.* TO '${JBPM_USER}'@'%' IDENTIFIED BY '${JBPM_PASSWORD}';"

# Create JBPMmicroscope tables
cd ${JBPM_DIRECTORY}/bin
./JBPMmicroscope showProcessDefinitions

# Insert JBPMmicroscope minimal data before deploy CRON
curl --output ${JBPM_DIRECTORY}/userJBPM.sh ${URL}/userJBPM.sh
cd ${JBPM_DIRECTORY}
chmod u+x userJBPM.sh
./userJBPM.sh mage root@localhost JBPMmicroscope

