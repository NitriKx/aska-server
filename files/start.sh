#!/bin/bash
# Location of server data and save data for docker

server_files=/home/aska/server_files
persistent_data=/home/aska/persistent_data

echo " "
echo "Server files location is set to : $server_files"
echo "Save files locaiton is set to : $persistent_data"
echo " "

mkdir -p /home/aska/.steam 2>/dev/null
chmod -R 777 /home/aska/.steam 2>/dev/null
echo " "
echo "Updating Aska Dedicated Server files..."
echo " "

if [ ! -z $BETANAME ];then
    if [ ! -z $BETAPASSWORD ]; then
        echo "Using beta $BETANAME with the password $BETAPASSWORD"
        steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "$server_files" +login anonymous +app_update "3246670 -beta $BETANAME -betapassword $BETAPASSWORD" validate +quit
    else
        echo "Using beta $BETANAME without a password!" 
        steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "$server_files" +login anonymous +app_update "3246670 -beta $BETANAME" validate +quit
    fi
else
    echo "No beta branch used."
    steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "$server_files" +login anonymous +app_update 3246670 validate +quit
fi

echo "steam_appid: "`cat $server_files/steam_appid.txt`
echo " "

echo "Checking if server_properties.txt files exists and no env virables were set"
if [ ! -f "$server_files/server_properties.txt" ]; then
    echo "$server_files/server_properties.txt not found. Copying default file."
    cp "/home/aska/scripts/server_properties.txt" "$server_files/" 2>&1
fi
echo " "

echo "Checking if CUSTOM_CONFIG env is set and if set to true:"
if [ ! -z $CUSTOM_CONFIG ]; then
    if [ $CUSTOM_CONFIG = true ];then
	    echo "Not changing app.cfg file"
	else
	    echo "Running setup script for the server_properties.txt file"
            source ./scripts/env2cfg.sh
	fi
    
else
    echo "Running setup script for the server_properties.txt file"
    source ./scripts/env2cfg.sh
fi
echo " "
echo "Cleaning possible X11 leftovers"
echo " "
if [ -f /tmp/.X0-lock ] || [ -d /tmp/ ]; then
    if [ -f /tmp/.X0-lock ]; then
        rm /tmp/.X0-lock > /dev/null 2>&1
    fi
    if [ -d /tmp/ ]; then
        rm -r /tmp/* > /dev/null 2>&1
    fi
fi

cd "$server_files"
echo "Starting Aska Dedicated Server"
echo " "
echo "Launching wine Aska"
echo " "
xvfb-run wine $server_files/AskaServer.exe -propertiesPath $server_files/server_properties.txt 2>&1
