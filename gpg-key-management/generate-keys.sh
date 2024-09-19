#!/usr/bin/env bash
# This script will generate a new GPG certify key and 
# Based on https://github.com/drduh/YubiKey-Guide

####################################################################################################
# SETUP
####################################################################################################
printf "########## 1. Set the requiered values\n"

read -r -p "##### Create identity, formatted as \"Firstname Lastname <e-mail@adress>\". Cant be empty. (default=\"user\"): " identity
if [[ -z "$identity" ]]; then
    identity="user"
fi

read -r -p "##### Key type [] (default=rsa4096): " key_type
if [[ -z "$key_type" ]]; then
    key_type="rsa4096"
fi

read -r -p "##### Set expiration time, relative time (2y, 30d ...) or exact date (2030-12-31) (default=2y): " expiration
if [[ -z "$expiration" ]]; then
    expiration=2y
fi

read -r -p "##### Set password for certify key, leave empty for none (default=\"\"): " password
if [[ -z "$password" ]]; then
    password=""
fi

temp_dir=$(mktemp -d -t gnupg-"$(date +%Y-%m-%d)"-XXXXXXXXXX)
export GNUPGHOME="$temp_dir"
printf "##### Created temporary directory for files in %s\n" "$GNUPGHOME"

printf "# https://github.com/drduh/config/blob/master/gpg.conf
# https://www.gnupg.org/documentation/manuals/gnupg/GPG-Options.html
# 'gpg --version' to get capabilities
# Use AES256, 192, or 128 as cipher
personal-cipher-preferences AES256 AES192 AES
# Use SHA512, 384, or 256 as digest
personal-digest-preferences SHA512 SHA384 SHA256
# Use ZLIB, BZIP2, ZIP, or no compression
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
# Default preferences for new keys
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
# SHA512 as digest to sign keys
cert-digest-algo SHA512
# SHA512 as digest for symmetric ops
s2k-digest-algo SHA512
# AES256 as cipher for symmetric ops
s2k-cipher-algo AES256
# UTF-8 support for compatibility
charset utf-8
# No comments in messages
no-comments
# No version in output
no-emit-version
# Disable banner
no-greeting
# Long key id format
keyid-format 0xlong
# Display UID validity
list-options show-uid-validity
verify-options show-uid-validity
# Display all keys and their fingerprints
with-fingerprint
# Display key origins and updates
#with-key-origin
# Cross-certify subkeys are present and valid
require-cross-certification
# Disable caching of passphrase for symmetrical ops
no-symkey-cache
# Output ASCII instead of binary
armor
# Enable smartcard
use-agent
# Disable recipient key ID in messages (breaks Mailvelope)
throw-keyids
# Default key ID to use (helpful with throw-keyids)
#default-key 0xFF00000000000001
#trusted-key 0xFF00000000000001
# Group recipient keys (preferred ID last)
#group keygroup = 0xFF00000000000003 0xFF00000000000002 0xFF00000000000001
# Keyserver URL
#keyserver hkps://keys.openpgp.org
#keyserver hkps://keys.mailvelope.com
#keyserver hkps://keyserver.ubuntu.com:443
#keyserver hkps://pgpkeys.eu
#keyserver hkps://pgp.circl.lu
#keyserver hkp://zkaan2xfbuxia2wpf7ofnkbz6r5zdbbvxbunvp5g2iebopbfc4iqmbad.onion
# Keyserver proxy
#keyserver-options http-proxy=http://127.0.0.1:8118
#keyserver-options http-proxy=socks5-hostname://127.0.0.1:9050
# Enable key retrieval using WKD and DANE
#auto-key-locate wkd,dane,local
#auto-key-retrieve
# Trust delegation mechanism
#trust-model tofu+pgp
# Show expired subkeys
#list-options show-unusable-subkeys
# Verbose output
#verbose" > "$GNUPGHOME"/gpg.conf

####################################################################################################
# GENERATE KEYS
####################################################################################################
# create new gpg certify key of given type, using given password, set given identity, never expire
gpg -q --batch --passphrase "$password" --quick-generate-key "$identity" "$key_type" cert never

# get key id
key_id=$(gpg -k --with-colons "$identity" | awk -F: '/pub/ { print $5 }')

# get key fingerprint 
key_fingerprint=$(gpg -k --with-colons "$identity" | awk -F: '/fpr/ { print $10 }')

###########################################################################
# GENERATE SUBKEYS
###########################################################################
# generate subkey for signing
gpg -q --batch --pinentry-mode=loopback --passphrase "$password" --quick-add-key "$key_fingerprint" "$key_type" sign "$expiration"
# generate subkey for encrypting data
gpg -q --batch --pinentry-mode=loopback --passphrase "$password" --quick-add-key "$key_fingerprint" "$key_type" encrypt "$expiration"
# generate subkey for authentication
gpg -q --batch --pinentry-mode=loopback --passphrase "$password" --quick-add-key "$key_fingerprint" "$key_type" auth "$expiration"

printf "##### The following keys have been created:\n %s\n" "$(gpg -K --keyid-format=long "$identity")"

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
            gpg --output "$backup_path"/"$key_id"-SECRET-Certify.key --batch --pinentry-mode=loopback --passphrase "$password" --armor --export-secret-keys "$key_id"
            # create backup of all subkeys
            gpg --output "$backup_path"/"$key_id"-SECRET-Subkeys.key --batch --pinentry-mode=loopback --passphrase "$password" --armor --export-secret-subkeys "$key_id"
            # create backup of public key
            gpg --output "$backup_path"/"$key_id"-PUBLIC-"$(date +%F)".asc --armor --export "$key_id"
        else
            exit
        fi

####################################################################################################
# CLEANUP
####################################################################################################
# remove temporary directory
rm -drf "$GNUPGHOME"

printf "########## Done creating keys!
    Make sure to remove the localy saved certify key!
    Backup your keys to a save device!\n"
