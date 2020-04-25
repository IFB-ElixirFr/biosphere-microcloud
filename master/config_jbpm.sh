#!/bin/sh -xe
###################################################################################
# Title: config_jbpm.sh
# Description: Create and set up JBPMmicroscope database.
# Usage: ./config_jbpm.sh URL JBPM_PROJECT_SRC MYSQL_HOST MYSQL_USER MYSQL_PASSWORD
# Date: 2020-04-23
###################################################################################

URL=$1
JBPM_PROJECT_SRC=$2
MYSQL_HOST=$3
MYSQL_USER=$4
MYSQL_PASSWORD=$5

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
cd ${JBPM_PROJECT_SRC}/bin
./JBPMmicroscope showProcessDefinitions

# Insert JBPMmicroscope minimal data before deploy CRON
curl --output ${JBPM_PROJECT_SRC}/userJBPM.sh ${URL}/userJBPM.sh
cd ${JBPM_PROJECT_SRC}
chmod u+x userJBPM.sh
./userJBPM.sh mage root@localhost JBPMmicroscope

