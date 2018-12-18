#!/bin/bash -xe

cd $1
MYSQL_HOST=$2
MYSQL_USER=$3
MYSQL_PASSWORD=$4

# Connection to mysql
mysql_request="mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD"

# Create databases 
$mysql_request -e "CREATE DATABASE GO_CPD"; # --databases (-B) option includes CREATE DATABASE and USE statements unfortunately --tables option overrides the --databases (-B) option
$mysql_request -e "CREATE DATABASE PUB_CPD"; # --databases (-B) option includes CREATE DATABASE and USE statements unfortunately --tables option overrides the --databases (-B) option

# Create SQL schemas
schemas_dir="sql_bases/schemas"
$mysql_request < $schemas_dir/pkgdb_schema.sql
$mysql_request < $schemas_dir/REFSEQDB_schema.sql
$mysql_request < $schemas_dir/GO_Conf_schema.sql
$mysql_request GO_CPD < $schemas_dir/GO_CPD_schema.sql
$mysql_request PUB_CPD < $schemas_dir/PUB_CPD_schema.sql

# Insert data
data_dir="sql_bases/data"
$mysql_request pkgdb < $data_dir/pkgdb_data.sql
$mysql_request GO_Conf < $data_dir/GO_Conf_data.sql

# Set values in configuration file
# TODO: do the same for MYSQL_HOST
conf_file=web_code/conf/confConstant.inc.php
sed -i "s/MYSQL_USER/\"${MYSQL_USER}\"/g" ${conf_file}
sed -i "s/MYSQL_PASSWORD/\"${MYSQL_PASSWORD}\"/g" ${conf_file}

# Copy web code in DOCUMENT_ROOT
cp -r -b -f web_code/* /var/www/html/
chown -R root:apache /var/www/html/*
chmod -R u=rwX,g=rX,o=rX /var/www/html/*

# Copy web scripts
