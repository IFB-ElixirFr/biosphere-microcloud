#!/bin/sh -xe

######################
# Start mysql docker #
######################

ss-display "Installing MySQL docker"

# Run mysql container and expose port
# We generate the password with the same command than the docker container
CONTAINER_NAME=mysql01
export MYSQL_ROOT_PASSWORD="$(pwgen -1 32)"
docker run --log-driver=journald --detach --name=${CONTAINER_NAME} --env="MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" -p 3306:3306 mysql:5.7

# Export password
ss-set mysqlRootPassword ${MYSQL_ROOT_PASSWORD}

##################
# MicroScope UDF #
##################

# Version to use
MIC_UDF_VERSION=0.4.7
# Packages needed (inside the container)
MIC_UDF_PACKAGES="build-essential procps libmysqlclient-dev"

ss-display "Preparing installation of MicroScope UDF"

# Install some packages inside the container
docker exec ${CONTAINER_NAME} sh -c "apt-get update && apt-get -y install ${MIC_UDF_PACKAGES}"

# Download, copy the files and uncompress the sources
curl -o lib_mysqludf_sequtils-${MIC_UDF_VERSION}.tar.gz https://www.genoscope.cns.fr/agc/ftp/lib_mysqludf_sequtils/lib_mysqludf_sequtils-${MIC_UDF_VERSION}.tar.gz
docker cp lib_mysqludf_sequtils-${MIC_UDF_VERSION}.tar.gz ${CONTAINER_NAME}:/
docker exec ${CONTAINER_NAME} tar -xzf lib_mysqludf_sequtils-${MIC_UDF_VERSION}.tar.gz

# MySQL must be started before installing the UDF so we actively wait a bit by testing the connection.
# This test is placed here just before the real installation.
ss-display "Waiting MySQL server to start"
MAX=10 # Max number of tests
i=1    # Number of tests already done
until false
do
  echo "Waiting MySQL server ("$i"/"$MAX")"
  # Test the connection (`mysql` is not installed on the server but inside docker)
  if docker exec ${CONTAINER_NAME} mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'quit'
  then
    break
  fi
  i=$(( i + 1))
  if [ $i -gt $MAX ]
  then
    echo "MySQL server took too long to start"
    exit 1
  fi
  echo "Waiting MySQL server"
  sleep 3
done
echo "MySQL server started"

# Compilation & installation (we need the password)
ss-display "Starting installation of MicroScope UDF"
docker exec ${CONTAINER_NAME} sh -c "\
cd lib_mysqludf_sequtils-${MIC_UDF_VERSION}/ && \
./configure && make install && MYSQL_USER=root MYSQL_PASSWORD=${MYSQL_ROOT_PASSWORD} make installdb
"
# Remove file and folder
docker exec ${CONTAINER_NAME} rm -rf lib_mysqludf_sequtils-${MIC_UDF_VERSION}.tar.gz lib_mysqludf_sequtils-${MIC_UDF_VERSION}

# Remove packages
docker exec ${CONTAINER_NAME} sh -c "apt-get -y remove ${MIC_UDF_PACKAGES} && apt-get -y autoremove"

####################
# Backend is ready #
####################

ss-set mysqlBackendReady "true"
ss-display "MySQL backend ready"

