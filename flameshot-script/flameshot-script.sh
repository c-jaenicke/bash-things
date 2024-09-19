#!/usr/bin/env bash
# Script for taking screenshots using flameshot.
# Screenshots will be saved in a specified folder, organized by subfolders with the date.
#
# Help:
#   $ flameshot-script.sh region|full
#   region: open flameshot to select the region to take a screenshot of, also allows editing te
#       screen.
#   full: take a screenshot of the whole screen.
#

date=$(date +%Y-%m-%d)
path="<PATH TO CREATE SUBFOLDERS AND SAVE IMAGES IN>"

cd "$path" || exit

# create folder with current date if not exists
if ! [ -d "$date" ]; then
    mkdir "$date"
fi

# mode selection
case $1 in
    region)
        flameshot gui --clipboard --path "./$date"
        ;;

    full)
        flameshot full --clipboard --path "./$date"
        ;;

    *)
        printf "flameshot-script [region | full]\n"
        ;;
esac

