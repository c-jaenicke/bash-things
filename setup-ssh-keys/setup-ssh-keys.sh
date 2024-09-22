#!/usr/bin/env bash
# Script to generate SSH keys and upload them to a system.
# This script can utilize a YubiKey to generate a SSH key.
#
# NOTES:
# Restore Key on Different Host
#   After setting up SSH on the YubiKey, you can regenerate the public key on different hosts.
#   Regenerate the public key using `ssh-keygen -K`
# 
# Remove Authorized Key from Server:
#   Edit the user-specific `authorized_keys` files in `/home/USER/.ssh`
#   Remove the line corresponding to the key you want to delete
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
# RESOURCES:
# https://developers.yubico.com/SSH/Securing_git_with_SSH_and_FIDO2.html
# https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html 
# https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key#telling-git-about-your-ssh-key
# https://gist.github.com/xirixiz/b6b0c6f4917ce17a90e00f9b60566278?permalink_comment_id=3810968
#

####################################################################################################
# FUNCTIONS
####################################################################################################
# Get key_comment for key. Use empty if no input.
get_input_comment () {
    read -r -p "##### (-C) Enter the key_comment to add to the new key (default=empty): " key_comment
    if [[ -z "$key_comment" ]]; then
        key_comment=""
    fi
}

# Get key_type of key to generate. Use standard ed25519 key if no input and no YubiKey used. If YubiKey used, set key_type to ed25519-sk.
get_input_type () {
    read -r -p "##### (-t) Enter the key_type of key you want to create (default=ed25519 | YubiKey default=ed25519-sk) [Regular: ed25519 | rsa] [Yubikey: ed25519-sk]: " key_type
    if [[ -z "$key_type" ]]; then
        if [[ "$yubikey" == "y" ]]; then
            key_type="ed25519-sk"
        else
            key_type="ed25519"
        fi
    fi
}

# Ask if user is using a YubiKey.
get_input_yubikey () {
    read -r -p "##### Are you using a Yubico Yubikey (with FIDO2) for this setup? If yes, plug it in and confirm! [y/N]: "
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        yubikey="y"
    else
        yubikey="n"
    fi
}

# Get filename to save new key under. Use name based on key_type of key used it no input.
get_input_filename () {
    read -r -p "##### (-f) Enter file in which to save the key (default=\"id_$1\"): " filename
    if [[ -z "$filename" ]]; then
        filename="id_$1"
    fi
}

# Get passphrase to add to key. Set none if no input.
get_input_passphrase () {
  read -r -p "##### (-N) Enter a passphrase to add to the key (default=empty): " key_passphrase
  if [[ -z "$key_passphrase" ]]; then
      key_passphrase=""
  fi
}

# Generate a new key pair with given values.
generate_key () {
    printf "########## 1. Create new key pair\n"
    if [[ -z "$yubikey" ]]; then
       get_input_yubikey
    fi
    if [[ -z "$key_comment" ]]; then
        get_input_comment
    fi
    if [[ -z "$key_type" ]]; then
        get_input_type
    fi
    if [[ -z "$key_passphrase" ]]; then
        get_input_passphrase
    fi
    if [[ -z "$filename" ]]; then
        get_input_filename "$key_type"
    fi

    printf "##### Creating a new key pair using the values:
    Using YuibKey: %s
    Type: %s
    Comment: %s
    Passphrase: %s\n" "$yubikey" "$key_type" "$key_comment" "$key_passphrase"
    printf "##### Saving files in %s/%s and %s/%s.pub\n" "$(pwd)" "$filename" "$(pwd)" "$filename"

    if [[ "$yubikey" == "y" ]]; then
        # Source: https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html (2024-09-19)
        ssh-keygen -f "$filename" -C "$key_comment" -t "$key_type" -a 100 -N "$key_passphrase" -O resident -O verify-required
    else
        ssh-keygen -f "$filename" -C "$key_comment" -t "$key_type" -a 100 -N "$key_passphrase"
    fi
}

# Upload a key to a system.
upload_key () {
    printf "########## 2. Upload a key\n"
    read -r -p "##### Add key to remote host? [y/N]: " -n 1
    printf "\n"
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        printf "##### Adding pub  key to  remote host\n"

        # If -u|upload is called directly, no filename is set. Ask user for path to identity.
        if [[ -z "$filename" ]]; then
            read -r -p "##### Enter the path to the new identity: " filename
        fi
        
        # Get data for server.
        read -r -p "##### Enter username for remote host to  add key for: " username
        read -r -p "##### Enter ip for remote host to  add key for: " ip
        read -r -p "##### Enter ssh port on remote host: " port

        # Copy key to server. Ask if password login is possible, if not get existing identity for certificate auth.
        read -r -p "##### Are you authenticating using an already existing and assigned identity? [y/N]: " -n 1
        printf "\n"
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            # Existing identity gets passed to ssh using -o parameter.
            read -r -p "##### Enter the path to that identity: " pathtoidentity
            ssh-copy-id -f -i "$filename" -o "IdentityFile $pathtoidentity" -p "$port" "$username"@"$ip"
        else
            ssh-copy-id -i "$filename" -p "$port" "$username"@"$ip"
        fi

        printf "##### Use 'ssh -i %s -p %s %s@%s' to connect to the remote host using the certificate.\n" "${filename/.pub/}" "$port" "$username" "$ip"
        printf "##### Important notes:\n\tMake sure to NOT use the .pub file of the key to authenticate!\n\tSet the correct permissions using chmod:
        644 for %s (public key)
        600 for %s (private key)!\n" "$filename" "${filename/.pub/}"
        printf "##### Consider adding 'IdentityFile %s/%s' and 'IdentitiesOnly yes' to section of the remote host in your .ssh/config file.\n" "$(pwd)" "$filename"
    fi
}

# Print a help string.
print_help () {
    printf "########## Help:
    $ setup-ssh-keys gen|upload|help|-h [-y] [-c comment] [-t key type] [-p passphrase] [-f filename]
        gen: generate a new key pair
        upload: upload a key to a system
        help|-h: print this help text
        -y: use a YubiKey
        -c: set comment for key
        -t: set key type (Regular: ed25519 | rsa) (Yubikey: ed25519-sk)
        -p: set passphrase for key
        -f: set filename for new key

    This script performs the following tasks:
        1. Generates a new key pair, with optional Yubikey integration.
        2. Uploads the key to a specified serv

    Make sure to plug your Yubikey in before using this script!\n"
}

####################################################################################################
# SCRIPT
####################################################################################################
while getopts "yhc:t:p:f:" option; do
    case $option in
        y)
            yubikey="y"
            ;;

        c)
          key_comment="$OPTARG"
          ;;

        t)
          key_type="$OPTARG"
          ;;

        p)
          key_passphrase="$OPTARG"
          ;;

        f)
          filename="$OPTARG"
          ;;

        h)
            print_help
            exit
            ;;
    esac
done

case $1 in
    help)
        print_help
        exit
        ;;

    gen)
        generate_key
        ;;

    upload)
        upload_key
        ;;

    *)
        generate_key
        upload_key 
        ;;
esac
