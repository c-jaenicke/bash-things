#!/usr/bin/env bash
# Script to export the configuration on all VMs, as .xml files, into the current folder.

# check if script is being run as sudo
# script can only get VMs in current namespace, e.g. user or root
if [[ "$EUID" -ne 0 ]]; then
    printf "##### WARNING: Running this script as non-root only gets the vms form the user space."
fi

# array of all VM names
mapfile -t vm_names< <(virsh list --all | awk 'NR > 2'| awk '{ print $2 }')

# iterate over array and dump xml file
for vm in "${vm_names[@]}"; do
    if [[ -n "$vm" ]]; then
        virsh dumpxml "${vm}" > "$(pwd)/$vm".xml
    fi
done

