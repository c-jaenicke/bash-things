#!/usr/bin/env bash
dir=$HOME
printf "########## Scanning dir: %s" "$dir"
clamscan --recursive --infected "$dir"
