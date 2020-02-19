#!/bin/bash
#git_clone="https://github.com/IFB-ElixirFr/biosphere-commons.git"
git_clone="https://github.com/lburlot/biosphere-commons.git"
git_dir="biosphere-commons"

get_global_repo()
{
    if [ ! -e /tmp/$git_dir ]; then
        git clone -b correct_errors $git_clone/ /tmp/$git_dir
    else
        cd /tmp/$git_dir
        git pull
    fi
}

get_script_for_install_slurm()
{
    if [ ! -e /scripts/cluster ]; then
        mkdir -p /scripts/cluster
    fi
    if [ ! -e /scripts/toolshed ]; then
        mkdir /scripts/toolshed
    fi
    if [ ! -e /scripts/cluster/slurm ]; then
        mkdir -p /scripts/cluster/slurm
    fi
    yes | cp -rf /tmp/$git_dir/scripts/requirements.txt /scripts/
    yes | cp -rf /tmp/$git_dir/scripts/allows_other_to_access_me.sh /scripts/
    yes | cp -rf /tmp/$git_dir/scripts/json_tool_shed.py /scripts/
    yes | cp -rf /tmp/$git_dir/scripts/toolshed/os_detection.sh /scripts/toolshed/
    yes | cp -rf /tmp/$git_dir/scripts/cluster/cluster_install.sh /scripts/cluster/
    yes | cp -rf /tmp/$git_dir/scripts/cluster/elasticluster.sh /scripts/cluster/
    yes | cp -rf /tmp/$git_dir/scripts/cluster/slurm/* /scripts/cluster/slurm
    yes | cp -rf /tmp/$git_dir/scripts/populate_hosts_with_components_name_and_ips.sh /scripts/
    chmod a+rx -R /scripts/
}
get_all_requirement_script()
{
    get_global_repo
    if [ -e /tmp/$git_dir ]; then
        get_script_for_install_slurm
        rm -rf /tmp/$git_dir
    else
        ss-abort "repository doesn't exist!"
    fi
}

# Source cluster_install script
get_all_requirement_script
apt install -y python-minimal
apt update -y
apt install requests==2.20.0
apt install -y python-pip
pip2 install -r /scripts/requirements.txt
source /scripts/cluster/cluster_install.sh
make_file_test_slurm /root/mydisk
