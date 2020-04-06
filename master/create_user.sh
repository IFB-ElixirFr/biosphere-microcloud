#!/bin/sh -xe
################################################################
# Title: create_user.sh
# Description: Create a MicroScope user
# Usage: ./create_user.sh login email role
# Date: 2020-04-06
################################################################

login=$1
email=$2
role=$3

DBConnect="mysql -h ${MYAGCHOST} -P ${MYAGCPORT} -u ${MYAGCUSER} -p${MYAGCPASS}"

# Read or generate password
if [ -z $PS1 ]
then
    # non-interactive
    PASS=$(pwgen 32 1)
else
    # interactive
    read PASS
fi
echo $PASS

# Encrypt it in MD5
MD5_PASS=$(echo -n $PASS | md5sum | awk '{print $1}')
   
$DBConnect ${MYAGCDB} -e "INSERT INTO Annotator(A_name, A_mail, A_pass, A_type) VALUES ('${login}', '${email}', '${MD5_PASS}', '${role}')"
