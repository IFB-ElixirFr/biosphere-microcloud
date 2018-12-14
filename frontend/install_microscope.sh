#!/bin/bash -xe

cd $1

# Get latest MicroScope code
curl -o microcloud.tar.gz https://www.genoscope.cns.fr/agc/ftp/MicroCloud/microcloud-latest.tar.gz
tar -xvf microcloud.tar.gz 

# Connection to mysql
mysql_hostname=$(ss-get mysql_hostname)
mysql_password=$(ss-get mysql_root_password)
mysql_user=root
mysql_request="mysql -u $mysql_user -h $mysql_hostname -p$mysql_password"

# Create databases 
$mysql_request -e "CREATE DATABASE GO_CPD"; # --databases (-B) option includes CREATE DATABASE and USE statements unfortunately --tables option overrides the --databases (-B) option
$mysql_request -e "CREATE DATABASE PUB_CPD"; # --databases (-B) option includes CREATE DATABASE and USE statements unfortunately --tables option overrides the --databases (-B) option

# Create SQL schemas
schemas_dir="microcloud/sql_bases/schemas"
$mysql_request < $schemas_dir/pkgdb_schema.sql
$mysql_request < $schemas_dir/REFSEQDB_schema.sql
$mysql_request < $schemas_dir/GO_Conf_schema.sql
$mysql_request GO_CPD < $schemas_dir/GO_CPD_schema.sql
$mysql_request PUB_CPD < $schemas_dir/PUB_CPD_schema.sql

# Insert data
data_dir="microcloud/sql_bases/datas"
$mysql_request pkgdb < $data_dir/pkgdb_data.sql
$mysql_request GO_Conf < $data_dir/GO_Conf_data.sql

# Copy web code in DOCUMENT_ROOT
cp -r -b -f microcloud/web_code/* /var/www/html/

# Copy web scripts
