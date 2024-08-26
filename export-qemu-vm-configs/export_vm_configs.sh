#!/usr/bin/env bash
# export all .xmls of all vms into current folder

if [[ "$EUID" -ne 0 ]]; then
    printf "##### WARNING: Running this script as non-root only gets the vms form the user space."
fi

#vm_names=m(virsh list --all | awk 'NR > 2'| awk '{ print $2 }') | mapfile
mapfile -t vm_names< <(virsh list --all | awk 'NR > 2'| awk '{ print $2 }')

for vm in "${vm_names[@]}"; do
    if [[ -n "$vm" ]]; then
        virsh dumpxml "${vm}" > "$(pwd)/$vm".xml
    fi
done

