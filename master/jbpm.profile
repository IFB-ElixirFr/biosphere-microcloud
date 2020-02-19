## JBPM PROFILE ##

JBPMDirectory=$1

# Databases
export MYAGCDB="pkgdb"
export CPDGODB="GO_CPD"
export CPDPUBDB="PUB_CPD"
export PRESTATIONDB="PRESTATIONDB"
export GORESDB="GO_RES"
export NGSDB="UNSEEN"
export EVOLGENODB="EvolGenome2"
export MYRNASEQDB="RNAseq"
export MYAGCMICROCYCDB="microcyc"
export DBWORKFLOW="DBWorkFlow"
export NCBIREFSEQDB="REFSEQDB"
export GENOMEPUBDB="GenomePubDB"

# DB connection
export MYAGCUSER="root"
export MYAGCPASS=$(ss-get mysql_root_password)
export MYAGCHOST=$(ss-get mysql_hostname)
export MYAGCPORT=3306

export MICROSCOPE_DBconnect="mysql -A -N -u${MYAGCUSER} -p${MYAGCPASS} -h${MYAGCHOST}"
alias mysqlagcdb="mysql -u${MYAGCUSER} -p${MYAGCPASS} -h${MYAGCHOST}"

# micJBPMwrapper
export PATH=${JBPMDirectory}/micJBPMwrapper/unix-noarch/bin:$PATH

export MICROSCOPE_LIB_SCRIPT=${JBPMDirectory}/micJBPMwrapper/unix-noarch/lib/microscope.lib
export MICROSCOPE_PATH_SCRIPT=${JBPMDirectory}/micJBPMwrapper/unix-noarch
export MICROSCOPE_CONF_SCRIPT=${JBPMDirectory}/micJBPMwrapper/unix-noarch/conf
export MICJBPMWRAPPER_ROOT=${JBPMDirectory}/micJBPMwrapper/unix-noarch
export MICJBPMWRAPPER_EXEDIR=${JBPMDirectory}/micJBPMwrapper/unix-noarch/bin
export MICJBPMWRAPPER_LIBDIR=${JBPMDirectory}/micJBPMwrapper/unix-noarch/lib

# bagsub
export PATH=${JBPMDirectory}:${PATH}

# Tomcat
export JBPM_PROJECT_SRC=${JBPMDirectory}/jbpmmicroscope

PATH=${JBPM_PROJECT_SRC}/bin:${PATH}
export PATH

TOMCAT_HOME=/opt/tomcat
export TOMCAT_HOME
JBPM_PROJECT_HOME=${JBPMDirectory}
export JBPM_PROJECT_HOME

alias tomcat_status='systemctl status tomcat'
alias tomcat_start='systemctl start tomcat'
alias tomcat_stop='systemctl stop tomcat'
alias tomcat_logs='tail -f -n 100 $TOMCAT_HOME/logs/catalina.out'

# Slurm
export SLURM_CPUS_ON_NODE=4
