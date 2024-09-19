#!/usr/bin/env bash
# This script will renew keys for a specific identity.
# Requires the certify key to be present.

####################################################################################################
# SET VALUES
####################################################################################################
read -r -p "##### Enter identity, used to find old keys (cant be empty): " identity
if [[ -z "$identity" ]]; then
    printf "##### IDENTITY CANT BE EMPTY!" && exit
fi

read -r -p "##### Set password for certify key, leave empty for none (default=empty): " password
if [[ -z "$password" ]]; then
    password=""
fi

read -r -p "##### Set NEW expiration time, relative time (2y, 30d ...) or exact date (2030-12-31) (default=2y): " expiration
if [[ -z "$expiration" ]]; then
    expiration=2y
fi

printf "##### Found following keys with identity %s: \n%s\n" "$identity" "$(gpg -K --keyid-format=long "$identity")"
read -r -p "##### Are the keys you want to renew in the list? [y/N]: "
if [[ $REPLY =~ ^[Nn]$ ]]; then
    printf "#### Make sure your keys are imported and available! Restart the script..."
    exit
fi

# get key id
key_id=$(gpg -k --with-colons "$identity" | awk -F: '/pub/ { print $5; exit }')

# get key fingerprint 
key_fingerprint=$(gpg -k --with-colons "$identity" | awk -F: '/fpr/ { print $10; exit }')

####################################################################################################
# RENEW KEYS
####################################################################################################
gpg --batch \
    --pinentry-mode=loopback \
    --passphrase "$password" \
    --quick-set-expire \
    "$key_fingerprint" \
    "$expiration" \
    $(gpg -K --with-colons "$identity" | awk -F: '/^fpr:/ { print $10 }' | tail -n "+2" | tr "\n" " ")

printf "##### Renewed the following keys for identity %s: \n%s\n" "$identity" "$(gpg -K --keyid-format=long "$identity")"

####################################################################################################
# CREATE BACKUP OF KEYS
####################################################################################################
        read -r -p "##### Do you want to create a backup of all keys? [y/N]: "
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -r -p "##### Where to store the backups (default=current folder): " backup_path
            if [[ -z "$backup_path" ]]; then
                backup_path="."
            fi
            # create backup of certify key
            gpg --output "$backup_path"/"$key_id"-SECRET-Certify.key \
                --batch \
                --pinentry-mode=loopback \
                --passphrase "$password" \
                --armor \
                --export-secret-keys "$key_id"

            # create backup of all subkeys
            gpg --output "$backup_path"/"$key_id"-SECRET-Subkeys.key \
                --batch \
                --pinentry-mode=loopback \
                --passphrase "$password" \
                --armor \
                --export-secret-subkeys "$key_id"

            # create backup of public key
            gpg --output "$backup_path"/"$key_id"-PUBLIC-"$(date +%F)".asc \
                --armor \
                --export "$key_id"
        else
            exit
        fi
