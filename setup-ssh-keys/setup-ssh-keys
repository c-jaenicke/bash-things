#!/usr/bin/env bash
# Script to generate and upload keys to a system.
# This script can utilise a YubiKey to generate a new key pair, the generated key will be saved on
# the YubiKey.
#
# NOTES:
#
# Restore Key on Different Host
#   After setting up SSH on the YubiKey, you can regenerate the public key on different hosts.
#   Regenerate the public key using `ssh-keygen -K`
# 
# Remove Authorized Key from Server:
#   Edit the user-specific `authorized_keys` files in `/home/USER/.ssh`
#   Remove the line corresponding to the key you want to delte
#
# Setup SSH key for Git:
#   Set git to use SSH keys to sign `git config --global gpg.format ssh`
#   Set the SSH key to use `git config --global user.signingkey /FULL/PATH/TO/PUBLIC-KEY`
#   Add the public key to your GitHub Profile <https://github.com/settings/keys>
#
#   Start the SSH agent using `eval "$(ssh-agent -s)"`
#   Add the key using `ssh-add /FULL/PATH/TO/PRIVATE-KEY`
#   Sign a commit using `git commit -S -m "COMMIT MESSAGE"`
#   Push a commit using `git push`
#
# MISC RESOURCES:
#
# https://developers.yubico.com/SSH/Securing_git_with_SSH_and_FIDO2.html
# https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html 
# https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key#telling-git-about-your-ssh-key
# https://gist.github.com/xirixiz/b6b0c6f4917ce17a90e00f9b60566278?permalink_comment_id=3810968
#

####################################################################################################
# FUNCTIONS
####################################################################################################
# generate a new key pair
generate_key_pair () {
    printf "########## 1. Create new key pair\n"

    # get all values and confirmation
    get_comment
    get_type_of_key
    get_filename "$type"

    printf "##### Creating a new key pair using the values:\n\tUse Yuibkey: %s\n\tType: %s\n\tComment: %s\n" "$yubikey" "$type" "$comment"
    printf "##### Saving files in %s/%s and %s/%s.pub\n" "$(pwd)" "$filename" "$(pwd)" "$filename"

    # generate new key here
    if [[ "$yubikey" == "y" ]]; then
        # Source: https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html (2024-09-19)
        ssh-keygen -f "$filename" -C "$comment" -t "$type" -a 100 -O resident -O verify-required
    else
        ssh-keygen -f "$filename" -C "$comment" -t "$type" -a 100
    fi
    
    # return filename here to use for uploading
}

# get the filename to save the new key under, if no input, use id_$type
get_filename () {
    read -r -p "##### (-f) Enter  file in which to save the key (default=\"id_$1\"): " filename
    # if filename is empty, use default one
    if [[ -z "$filename" ]]; then
        filename="id_$1"
    fi
}

# get comment to add to key, if empty use empty
get_comment () {
    read -r -p "##### (-C) Enter the comment to add to the new key (default=\"\"): " comment
    # if input is empty, use empty
    if [[ -z "$comment" ]]; then
        comment=""
    fi
}

# get the type of key to create
get_type_of_key () {
    read -r -p "##### (-t) Enter the type of key you want to create (default=\"ed25519\") [Regular: ed25519 | rsa] [Yubikey: ed25519-sk]: " type
    # if input is empty, use default type ed25519
    if [[ -z "$type" ]]; then
        # if empty, set to default YubiKey or regular type 
        if [[ "$yubikey" == "y" ]]; then
            type="ed25519-sk"
        else
            type="ed25519"
        fi
    fi
}

# upload the key
upload_key () {
    # need username, ip and port for initial access
    printf "########## 2. Upload the key\n"
    read -r -p "##### Add key to remote host? [y/N]: " -n 1
    printf "\n"
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        printf "##### Adding pub  key to  remote host\n"
        
        # if no filename given, ask user
        if [[ -z "$filename" ]]; then
            read -r -p "##### Enter the path to the new identity: " filename
        fi
        
        # read server data
        read -r -p "##### Enter username for remote host to  add key for: " username
        read -r -p "##### Enter ip for remote host to  add key for: " ip
        read -r -p "##### Enter ssh port on remote host: " port
        
        # copy key to server, ask if user needs to authenticate with an identity
        read -r -p "Are you authenticating using an already existing and assigned identity? [y/N]: " -n 1
        printf "\n"
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            # pass existing identity to ssh using -o
            read -r -p "Enter the path to that identity: " pathtoidentity
            ssh-copy-id -f -i "$filename" -o "IdentityFile $pathtoidentity" -p "$port" "$username"@"$ip"
        else
            ssh-copy-id -i "$filename" -p "$port" "$username"@"$ip"
        fi

        # print steps after key as been added
        printf "##### Use 'ssh -i %s -p %s %s@%s' to connect to the remote host using the certificate.\n" "${filename/.pub/}" "$port" "$username" "$ip"
        printf "##### Important notes:
    Make sure to NOT use the .pub file of the key to authenticate!
    Set the correct permissions using chmod: 
        644 for %s (public key)
        600 for %s (private key)!\n" "$filename" "${filename/.pub/}"
        printf "##### Consider adding 'IdentityFile %s/%s' and 'IdentitiesOnly yes' to section of the remote host in your .ssh/config file.\n" "$(pwd)" "$filename"
    fi
}

# print a help string
print_help () {
    printf "########## Help:
    $ setup-ssh-keys [-h|help] [-g|gen] [-u|upload]
        -h|help: print this help text
        -g|gen: generate a new key
        -u|upload: upload a key

    This script performs the following tasks:
        1. Generates a new key pair, with optional Yubikey integration.
        2. Uploads the key to a specified serv

    Make sure to plug your Yubikey in before using this script!\n\n"
}

####################################################################################################
# SCRIPT
####################################################################################################
case $1 in
    -h|help)
        print_help
        ;;

    -g|gen)
        generate_key_pair
        ;;

    -u|upload)
        upload_key
        ;;

    *)
        print_help
        read -r -p "##### Are you using a Yubico Yubikey (with FIDO2) for this setup? If yes, plug it in and confirm! [y/N]: "
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            yubikey="y"
        else
            yubikey="n"
        fi

        generate_key_pair
        upload_key 
        ;;
esac

