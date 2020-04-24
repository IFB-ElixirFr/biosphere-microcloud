#!/bin/sh -xe
###################################################################
# Title: install_jbpm.sh
# Description: Install jBPM
# Usage: ./install_jbpm.sh URL JBPMDirectory JBPMResult TOMCAT_HOME
# Date: 2020-04-23
###################################################################

URL=$1
JBPMDirectory=$2
JBPMResult=$3
TOMCAT_HOME=$4

mkdir -p ${JBPMDirectory}
chmod g+s ${JBPMDirectory}
mkdir -p ${JBPMDirectory}/lib
mkdir -p ${JBPMDirectory}/bin
mkdir -p ${JBPMDirectory}/jbpmmicroscope
mkdir -p ${JBPMResult}
chmod g+s ${JBPMResult}
mkdir -p ${JBPMResult}/log

# Get jars
curl --output ${JBPMDirectory}/lib/jbpmmicroscope.jar ${URL}/jbpmmicroscope-client-latest.jar
curl --output ${JBPMDirectory}/lib/SystemActorsLauncher.jar ${URL}/SystemActorsLauncher-latest.jar

# Extract sources and bin from jbpmmicroscope.jar
cd ${JBPMDirectory}/jbpmmicroscope
jar -xf ${JBPMDirectory}/lib/jbpmmicroscope.jar
mv JBPMmicroscope ${JBPMDirectory}/bin/JBPMmicroscope
chmod +x ${JBPMDirectory}/bin/JBPMmicroscope

# Download tomcat 9
cd ${JBPMDirectory}
curl -O ${URL}/apache-tomcat-latest.tar.gz
mkdir -p ${JBPMDirectory}/tomcat
tar xf apache-tomcat-latest.tar.gz -C ${JBPMDirectory}/tomcat --strip-components=1
rm apache-tomcat-latest.tar.gz

# Create Tomcat User
groupadd tomcat
useradd -s /bin/false -g tomcat -d ${TOMCAT_HOME} tomcat

# Update Permissions
chown -R tomcat:tomcat ${TOMCAT_HOME}
chown -R tomcat:tomcat ${AGC_PRODUCTSHOME}

cd ${JBPMDirectory}/tomcat
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
chown -R tomcat:tomcat ${JBPMResult}

# Create setenv.sh
cat <<EOF> ${JBPMDirectory}/tomcat/bin/setenv.sh
export CATALINA_OPTS="\$CATALINA_OPTS -Xms512m -Xmx2g -server"
EOF

# Download jbpm war into tomcat/webapps dir
curl --output ${JBPMDirectory}/tomcat/webapps/jbpmmicroscope.war ${URL}/jbpmmicroscope-server-latest.war

# Update context.xml
cat <<EOF> ${JBPMDirectory}/tomcat/webapps/manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
    allow="\d+\.\d+\.\d+\.\d+" />
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOF

