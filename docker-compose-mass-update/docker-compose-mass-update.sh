#!/usr/bin/env bash
# This script updates all given docker compose stacks.

# create array of paths to docker compose files
folders=("/PATH/TO/docker-compose.yml")

# iterate over paths and update stacks
for folder in "${folders[@]}"; do
    printf "##### Updating folder %s\n" "$folder"
    cd "$folder" || return
    sudo docker compose pull && sudo docker compose down && sudo docker compose up -d
    printf "##### Done updating folder %s\n" "$folder"
done

