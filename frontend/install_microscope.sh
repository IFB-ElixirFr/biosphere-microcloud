#!/bin/bash

set -e
set -u
set -o pipefail

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
$mysql_request pkgdb < $data_dir/pkgdb_Maintenance_Country_Amiga_Params_data.sql
$mysql_request pkgdb < $data_dir/pkgdb_Annotator_data.sql
$mysql_request pkgdb < $data_dir/pkgdb_Sid_Config_data.sql
$mysql_request pkgdb < $data_dir/pkgdb_Sequence_Checkpoint_Desc_data.sql
$mysql_request GO_Conf < $data_dir/GO_Conf_data.sql

# Insert data for Oid=31
$mysql_request pkgdb < $data_dir/pkgdb_Organism_O_Taxonomy_Replicon_data.sql

# Insert minimal data into pkgdb
$mysql_request -e "insert into pkgdb.Organism values (0,'Organism','INIT',null,2323,'init','-','bac',1,'Organism_init')";
$mysql_request -e "insert into pkgdb.Replicon values(0,1,'INIT',1,'unknown','unknown',11,1,0,null,null,0,now(),'REFERENCE','initialisation',null,null)";
$mysql_request -e "insert into pkgdb.Sequence values (0,1,'1.fna',0,'INIT_v1_','INIT_v1_',0,now(),now(),null,'inProduction','public')";
$mysql_request -e "insert into pkgdb.Annotator_Access_Rights values (1,1,'view',now())";

# Set values in configuration file
conf_file=web_code/conf/confConstant.inc.php
sed -i "s/MYSQL_USER/\"${MYSQL_USER}\"/g" ${conf_file}
sed -i "s/MYSQL_PASSWORD/\"${MYSQL_PASSWORD}\"/g" ${conf_file}
sed -i "s/MYSQL_HOST/\"${MYSQL_HOST}\"/g" ${conf_file}

# Copy web code in DOCUMENT_ROOT
cp -r -b -f web_code/* /var/www/html/
chown -R root:apache /var/www/html/*
chmod -R u=rwX,g=rX,o=rX /var/www/html/*

# Copy web scripts
