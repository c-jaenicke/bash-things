#!/usr/bin/env bash
# script for setting up ssh keys for remote hosts

# generate new key pair
printf "##### 1. Create new key pair\n"
read -r -p "Enter  file in which to save the key: " filename
# if filename is empty, use default one
if [[ -z "$filename" ]]; then
    filename="id_ed25519"
fi
printf "##### Saving files in %s/%s and %s/%s.pub\n", "$(pwd)" "$filename" "$(pwd)" "$filename"
ssh-keygen -f "$filename"

# add public key to remote host
# need username, ip and port for initial access
read -r -p "Add key to remote host? [y/N]: " -n 1
printf "\n"
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    printf "##### Adding pub  key to  remote host\n"
    read -r -p "Enter username for remote host to  add key for: " username
    read -r -p "Enter ip for remote host to  add key for: " ip
    read -r -p "Enter ssh port on remote host: " port
    ssh-copy-id -i "$filename" -p "$port" "$username"@"$ip"

    printf "##### Use 'ssh -i %s -p %s %s@%s' to connect to the remote host using the certificate.\n", "$filename" "$port" "$username" "$ip"
    printf "##### Or consider adding 'IdentityFile %s/%s' and 'IdentitiesOnly yes' to section of the remote host in your .ssh/config file.", "$(pwd)" "$filename"
fi
