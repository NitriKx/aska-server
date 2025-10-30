#!/bin/bash

ORIGINAL_FILE="/home/ubuntu/scripts/server properties.txt"
DESTINATION_FILE="/home/ubuntu/server_files/server properties.txt"

variables=(    
    "SERVER_NAME" "server name"
    "PASSWORD" "password"
    "SERVER_PORT" "steam game port"
    "SERVER_QUERY_PORT" "steam query port"
    "AUTHENTICATION_TOKEN" "authentication token"
    "REGION" "region"
    "KEEP_WORLD_ALIVE" "keep server world alive"
    "AUTOSAVE_STYLE" "autosave style"
    "SAVE_ID" "save id"
    "SEED" "seed"
)

cp -f "$ORIGINAL_FILE" "$DESTINATION_FILE"

for ((i=0; i<${#variables[@]}; i+=2)); do
    var_name=${variables[$i]}
    config_name=${variables[$i+1]}

    if [ ! -z "${!var_name}" ]; then
        echo "${config_name} set to: ${!var_name}"
        if grep -q "$config_name" "$DESTINATION_FILE"; then
            sed -i "s|^$config_name =.*$|$config_name = ${!var_name}|g" "$DESTINATION_FILE"
        else
            echo -ne "\n$config_name = ${!var_name}" >> "$DESTINATION_FILE"
        fi
    fi
done
