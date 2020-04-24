#!/bin/bash -xe

source /scripts/allows_other_to_access_me.sh --dry-run

auto_gen_users
publish_pubkey
allow_others

source /scripts/populate_hosts_with_components_name_and_ips.sh --dry-run

populate_hosts_with_components_name_and_ips_on_vm_remove hostname

