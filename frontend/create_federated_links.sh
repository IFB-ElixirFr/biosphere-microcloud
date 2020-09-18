#!/bin/sh -xe

######################################
# Title: create_federated_links.sh
# Description: This script will create all the federated links between the permanent VM and the backend component.
# We use the 'SHOW CREATE TABLE' statement to rewrite the 'CREATE TABLE' statement to our convenience.
# DB databases were created in the permanent VM with 'microscopeCreateDBschemas.py'
# Usage:$ ./create_federated_links.sh PERMANENT_MYSQL_HOST PERMANENT_MYSQL_PORT PERMANENT_MYSQL_USER PERMANENT_MYSQL_PASSWORD BACKEND_MYSQL_HOST BACKEND_MYSQL_USER BACKEND_MYSQL_PASSWORD
# Author:
# Date: 03/04/2019
######################################

# Permanent VM connection parameters
PERMANENT_MYSQL_HOST=$1
PERMANENT_MYSQL_PORT=$2
PERMANENT_MYSQL_USER=$3
PERMANENT_MYSQL_PASSWORD=$4

# Create connection variable to access permanent VM mysql server
permanent_mysql_request="mysql -h ${PERMANENT_MYSQL_HOST} -u ${PERMANENT_MYSQL_USER} -p${PERMANENT_MYSQL_PASSWORD}"

# Backend component connection parameters:
BACKEND_MYSQL_HOST=$5
BACKEND_MYSQL_USER=$6
BACKEND_MYSQL_PASSWORD=$7

# Create connection variable to access backend mysql server
backend_mysql_request="mysql -h ${BACKEND_MYSQL_HOST} -u ${BACKEND_MYSQL_USER} -p${BACKEND_MYSQL_PASSWORD}"

# Get databases listing
databases=$(${permanent_mysql_request} -e 'SHOW DATABASES;')

## Write databases and federated servers creation statement
# Do not take into account the default system schemas/databases; those are mysql, information_schema, performance_schema and sys
for db in ${databases[@]}; do
  if [ ${db} != "Database" ] && [ ${db} != "mysql" ] && [ ${db} != "information_schema" ] && [ ${db} != "performance_schema" ] && [ ${db} != "sys" ] && [ ${db} != "phpmyadmin" ] && [ ${db} != "test" ]; then
    ${backend_mysql_request} -e "CREATE DATABASE ${db};\nCREATE SERVER federatedlink_${db}
    FOREIGN DATA WRAPPER mysql
    OPTIONS (USER '${PERMANENT_MYSQL_USER}', HOST '${PERMANENT_MYSQL_HOST}', DATABASE '${db}', PORT ${PERMANENT_MYSQL_PORT}, Password '${PERMANENT_MYSQL_PASSWORD}')";
  fi
done

# Write federated tables creation statements
# Replace MYISAM engine by FEDERATED engine in the 'CREATE TABLE' statement
# Remove 'Table Create Table' and '\ n' expressions that are not needed
for db in ${databases[@]}; do
  if [ ${db} != "Database" ] && [ ${db} != "mysql" ] && [ ${db} != "information_schema" ] && [ ${db} != "performance_schema" ] && [ ${db} != "sys" ] && [ ${db} != "phpmyadmin" ] && [ ${db} != "test" ]; then
    tables=$(${permanent_mysql_request} -e "SHOW TABLES from ${db}";);
    for table in ${tables[@]}; do
      if [ ${table} != "Tables_in_${db}" ]; then
        chaine=$(${permanent_mysql_request} ${db} -e "SHOW CREATE TABLE ${table}");
        value=$(echo ${chaine} | sed "s/) ENGINE=.*/) ENGINE=FEDERATED DEFAULT CHARSET=latin1 CONNECTION='federatedlink_"${db}"\/"${table}"';/g" | sed "s/Table Create Table ${table} /\n/g" | sed "s/\\\n//g")
        ${backend_mysql_request} -e "use ${db};\n${value}"
      fi
    done
  fi
done

