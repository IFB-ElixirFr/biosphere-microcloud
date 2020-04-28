#!/bin/sh -xe
###############################################################################################
# Title: install_jbpm.sh
# Description: Install jBPM
# Usage: ./install_jbpm.sh URL JBPM_PROJECT_SRC JBPM_PROJECT_HOME TOMCAT_HOME AGC_PRODUCTSHOME
# Date: 2020-04-23
###############################################################################################

URL=$1
JBPM_PROJECT_SRC=$2
JBPM_PROJECT_HOME=$3
TOMCAT_HOME=$4
AGC_PRODUCTSHOME=$5

mkdir -p ${JBPM_PROJECT_SRC}
chmod g+s ${JBPM_PROJECT_SRC}
mkdir -p ${JBPM_PROJECT_SRC}/lib
mkdir -p ${JBPM_PROJECT_SRC}/bin
mkdir -p ${JBPM_PROJECT_SRC}/jbpmmicroscope
mkdir -p ${JBPM_PROJECT_HOME}
chmod g+s ${JBPM_PROJECT_HOME}
mkdir -p ${JBPM_PROJECT_HOME}/log

# Get jars
curl --output ${JBPM_PROJECT_SRC}/lib/jbpmmicroscope.jar ${URL}/jbpmmicroscope-client-latest.jar
curl --output ${JBPM_PROJECT_SRC}/lib/SystemActorsLauncher.jar ${URL}/SystemActorsLauncher-latest.jar

# Extract sources and bin from jbpmmicroscope.jar
cd ${JBPM_PROJECT_SRC}/jbpmmicroscope
jar -xf ${JBPM_PROJECT_SRC}/lib/jbpmmicroscope.jar
mv JBPMmicroscope ${JBPM_PROJECT_SRC}/bin/JBPMmicroscope
chmod +x ${JBPM_PROJECT_SRC}/bin/JBPMmicroscope

# Download tomcat 9
cd ${JBPM_PROJECT_SRC}
curl -O ${URL}/apache-tomcat-latest.tar.gz
mkdir -p ${JBPM_PROJECT_SRC}/tomcat
tar xf apache-tomcat-latest.tar.gz -C ${JBPM_PROJECT_SRC}/tomcat --strip-components=1
rm apache-tomcat-latest.tar.gz

# Create Tomcat User
groupadd tomcat
useradd -s /bin/false -g tomcat -d ${TOMCAT_HOME} tomcat

# Update Permissions
chown -R tomcat:tomcat ${TOMCAT_HOME}
chown -R tomcat:tomcat ${AGC_PRODUCTSHOME}

cd ${JBPM_PROJECT_SRC}/tomcat
chmod -R g+r conf
chmod g+x conf

# Configure Tomcat Web Management Interface
TOMCAT_USER=$(ss-get tomcat_user)
TOMCAT_PASSWORD=$(ss-get tomcat_password)

cd ${TOMCAT_HOME}/conf

# Create temp file
head -36 tomcat-users.xml>tomcat-users.xml.tmp
cat <<EOF>> tomcat-users.xml.tmp
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<role rolename="admin"/>
<user username="${TOMCAT_USER}" password="${TOMCAT_PASSWORD}" roles="manager-gui,admin-gui,admin,manager,manager-script,admin-script"/>
</tomcat-users>
EOF

# Delete temp file
mv tomcat-users.xml.tmp tomcat-users.xml

# Change dir ownership
chown -R tomcat:tomcat ${JBPM_PROJECT_HOME}

# Create setenv.sh
cat <<EOF> ${JBPM_PROJECT_SRC}/tomcat/bin/setenv.sh
export CATALINA_OPTS="\$CATALINA_OPTS -Xms512m -Xmx2g -server"
EOF

# Download jbpm war into tomcat/webapps dir
curl --output ${JBPM_PROJECT_SRC}/tomcat/webapps/jbpmmicroscope.war ${URL}/jbpmmicroscope-server-latest.war

# Update context.xml
cat <<EOF> ${JBPM_PROJECT_SRC}/tomcat/webapps/manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
    allow="\d+\.\d+\.\d+\.\d+" />
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOF

