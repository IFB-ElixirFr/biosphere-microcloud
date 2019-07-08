#!/bin/sh -xe

######################################
# Title: import_Oid.sh
# Description: This script will import MicroScope data into backend component for a chosen Oid 
# Usage:$ ./import_Oid dirname Oid MYSQL_HOST MYSQL_USER MYSQL_PASSWORD
# Date: 03/04/2019
######################################

cd $1
Oid=$2
MYSQL_HOST=$3
MYSQL_USER=$4
MYSQL_PASSWORD=$5

# Get the latest database version 
URL=https://www.genoscope.cns.fr/agc/ftp/MicroCloud/microscope_${Oid}-latest.tar.gz
curl -o microscope_${Oid}.tar.gz $URL
tar -xvf microscope_${Oid}.tar.gz

# Connection to mysql
mysql_request="mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD"

# Remove "ONLY_FULL_GROUP_BY" from sql_mod
# It is necessary to display the 'Display Preferences' page
# It prevents 'this is incompatible with sql_mode=only_full_group_by.' error.
$mysql_request -e "SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'";
$mysql_request -e "SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'";

# Create GO_SPE database
 $mysql_request -e "CREATE DATABASE GO_SPE";

# Import list of Sid
data_dir="${Oid}/sql_bases/data"
file=${data_dir}/Sid_list.txt

# Create list of Sid
Sids=( $(tail -n +2 $file) )

# Create PUB_CPD and GO_CPD tables based on template
# We need one table by Sid
for Sid in ${Sids[@]}; do
  $mysql_request -e "CREATE TABLE GO_CPD.${Sid}_GO_GO_CPD LIKE GO_CPD.Sid_GO_GO_CPD";
  $mysql_request -e "CREATE TABLE GO_CPD.${Sid}_GO_GO_CPD_lst LIKE GO_CPD.Sid_GO_GO_CPD_lst";
  $mysql_request -e "CREATE TABLE GO_CPD.${Sid}_GO_Synton LIKE GO_CPD.Sid_GO_Synton";
  $mysql_request -e "CREATE TABLE PUB_CPD.${Sid}_GO_RefSeq_CPD LIKE PUB_CPD.Sid_GO_RefSeq_CPD";
  $mysql_request -e "CREATE TABLE PUB_CPD.${Sid}_GO_RefSeq_CPD_lst LIKE PUB_CPD.Sid_GO_RefSeq_CPD_lst";
  $mysql_request -e "CREATE TABLE PUB_CPD.${Sid}_GO_RefSeq_Synton LIKE PUB_CPD.Sid_GO_RefSeq_Synton";
done

# Create GO_SPE schema
schemas_dir="${Oid}/sql_bases/schemas"
$mysql_request GO_SPE < $schemas_dir/GO_SPE_schema.sql

# Insert data for chosen Oid
$mysql_request pkgdb < ${data_dir}/pkgdb_data.sql
$mysql_request GO_RES < ${data_dir}/GO_RES_data.sql
$mysql_request GO_CPD < ${data_dir}/GO_CPD_data.sql
$mysql_request PUB_CPD < ${data_dir}/PUB_CPD_data.sql
$mysql_request GO_SPE < ${data_dir}/GO_SPE_data.sql

# Copy web data
cd "${Oid}/web_data"
chown -R root:apache /var/www/*
chmod -R u=rwx,g=rx,o=rx /var/www/*
cp -avr * /var/www/agc_data/

