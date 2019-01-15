#!/bin/bash

set -e
set -u
set -o pipefail

cd $1
MYSQL_HOST=$3
MYSQL_USER=$4
MYSQL_PASSWORD=$5

# Connection to mysql
mysql_request="mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD"

# Create agc user
$mysql_request -e "CREATE USER 'agc'@'%'";
$mysql_request -e "GRANT ALL ON pkgdb.* TO 'agc'@'%'";
$mysql_request -e "FLUSH PRIVILEGES";

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
$mysql_request < $schemas_dir/GO_RES_schema.sql

# Create PUB_CPD and GO_CPD tables based on template
$mysql_request -e "CREATE TABLE GO_CPD.36_GO_GO_CPD LIKE GO_CPD.Sid_GO_GO_CPD";
$mysql_request -e "CREATE TABLE GO_CPD.36_GO_GO_CPD_lst LIKE GO_CPD.Sid_GO_GO_CPD_lst";
$mysql_request -e "CREATE TABLE GO_CPD.36_GO_Synton LIKE GO_CPD.Sid_GO_Synton";
$mysql_request -e "CREATE TABLE PUB_CPD.36_GO_RefSeq_CPD LIKE PUB_CPD.Sid_GO_RefSeq_CPD";
$mysql_request -e "CREATE TABLE PUB_CPD.36_GO_RefSeq_CPD_lst LIKE PUB_CPD.Sid_GO_RefSeq_CPD_lst";
$mysql_request -e "CREATE TABLE PUB_CPD.36_GO_RefSeq_Synton LIKE PUB_CPD.Sid_GO_RefSeq_Synton";

# Insert minimal data
data_dir="sql_bases/data"
$mysql_request pkgdb < $data_dir/pkgdb_Maintenance_Country_Amiga_Params_data.sql
$mysql_request pkgdb < $data_dir/pkgdb_Annotator_data.sql
$mysql_request pkgdb < $data_dir/pkgdb_Sequence_Checkpoint_Desc_data.sql
$mysql_request GO_Conf < $data_dir/GO_Conf_data.sql
$mysql_request GO_RES < $data_dir/GO_RES_ORGCLUST_clustering_param_ORGCLUST_distance_param_data.sql

# Insert data for O_id=31 and S_id=36
cd "../$2"
oid_data_dir="data"
$mysql_request pkgdb < $oid_data_dir/pkgdb_Oid_data.sql
$mysql_request pkgdb < $oid_data_dir/pkgdb_Sid_data.sql
$mysql_request GO_CPD < $oid_data_dir/GO_CPD_Sid_data.sql
$mysql_request PUB_CPD < $oid_data_dir/PUB_CPD_Sid_data.sql
$mysql_request pkgdb < $oid_data_dir/pkgdb_Annotator_Access_Rights_Oid_data.sql
$mysql_request GO_RES < $oid_data_dir/GO_RES_GO_FEAT_data.sql
$mysql_request GO_RES < $oid_data_dir/GO_RES_Sid_data.sql
$mysql_request GO_RES < $oid_data_dir/GO_RES_ASid_data.sql
$mysql_request GO_RES < $oid_data_dir/GO_RES_ASid1_ASid2_data.sql

# Insert data for O_id=16 and S_id=247 (REFSEQDB data)
$mysql_request REFSEQDB < $oid_data_dir/REFSEQDB_Organism_Sequence_data.sql
$mysql_request REFSEQDB < $oid_data_dir/REFSEQDB_Org_Info_Taxon_data.sql
$mysql_request REFSEQDB < $oid_data_dir/REFSEQDB_O_Taxonomy_data.sql
$mysql_request REFSEQDB < $oid_data_dir/REFSEQDB_Nodes_Names_data.sql
$mysql_request REFSEQDB < $oid_data_dir/REFSEQDB_Genomic_Object_data.sql
$mysql_request REFSEQDB < $oid_data_dir/REFSEQDB_PB_GO_CPD_data.sql
$mysql_request REFSEQDB < $oid_data_dir/REFSEQDB_Division_data.sql

# Copy web data
cd "web_data"
mkdir -p /var/www/agc_data/Acinetobacter_sp_ADP1/
cp -R Acinetobacter_sp_ADP1/ /var/www/agc_data/Acinetobacter_sp_ADP1/
chown -R root:apache /var/www/agc_data/*
chmod -R u=rwX,g=rX,o=rX /var/www/agc_data/*

# Set values in configuration file
cd "../../$1"
conf_file=web_code/conf/confConstant.inc.php
sed -i "s/MYSQL_USER/\"${MYSQL_USER}\"/g" ${conf_file}
sed -i "s/MYSQL_PASSWORD/\"${MYSQL_PASSWORD}\"/g" ${conf_file}
sed -i "s/MYSQL_HOST/\"${MYSQL_HOST}\"/g" ${conf_file}

# Copy web code in DOCUMENT_ROOT
cp -r -b -f web_code/* /var/www/html/
chown -R root:apache /var/www/html/*
chmod -R u=rwX,g=rX,o=rX /var/www/html/*

# Copy web scripts
mkdir /var/www/binphp/
cp -r -b -f web_scripts/* /var/www/binphp/
