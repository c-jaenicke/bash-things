#!/usr/bin/env bash
dir="/"
printf "########## Scanning dir: %s" "$dir"
clamscan --recursive --infected --exclude-dir='^/sys|^/dev' "$dir"
