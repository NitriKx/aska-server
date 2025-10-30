#!/bin/bash
# Location of server data and save data for docker

server_files=/home/ubuntu/server_files

echo " "
echo "Server files location is set to : $server_files"
echo " "

mkdir -p /home/ubuntu/.steam 2>/dev/null
chmod -R 777 /home/ubuntu/.steam 2>/dev/null
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

echo "Checking if server properties.txt files exists and no env variables were set"
if [ ! -f "$server_files/server properties.txt" ]; then
    echo "$server_files/server properties.txt not found. Copying default file."
    cp "/home/ubuntu/scripts/server properties.txt" "$server_files/" 2>&1
fi
echo " "

echo "Checking if CUSTOM_CONFIG env is set and if set to true:"
if [ ! -z $CUSTOM_CONFIG ]; then
    if [ $CUSTOM_CONFIG = true ];then
	    echo "Not changing app.cfg file"
	else
	    echo "Running setup script for the server properties.txt file"
        source ./scripts/env2cfg.sh
	fi
else
    echo "Running setup script for the server properties.txt file"
    source ./scripts/env2cfg.sh
fi

cd "$server_files"

# Start health check server in background
echo "Starting health check server on port 8080..."
python3 /home/ubuntu/scripts/healthcheck.py > /tmp/healthcheck.log 2>&1 &
HEALTHCHECK_PID=$!
echo "Health check server started with PID: $HEALTHCHECK_PID"
echo " "

# Check and install SDL3.dll if missing
if [ ! -f "$server_files/SDL3.dll" ]; then
    echo "SDL3.dll not found. Downloading..."
    # Download SDL3.dll for Windows from official repository
    wget -q "https://github.com/libsdl-org/SDL/releases/download/release-3.2.0/SDL3-3.2.0-win32-x64.zip" -O /tmp/sdl3.zip
    if [ $? -eq 0 ]; then
        echo "Extracting SDL3.dll..."
        unzip -j /tmp/sdl3.zip "SDL3.dll" -d "$server_files/" 2>&1
        rm /tmp/sdl3.zip
        echo "SDL3.dll installed successfully"
    else
        echo "WARNING: Failed to download SDL3.dll. Server may not start properly."
    fi
else
    echo "SDL3.dll found in server directory"
fi
echo " "

echo "Starting Aska Dedicated Server"
echo " "
echo "Launching wine Aska"
echo " "

# Run xvfb with verbose error output
echo "Starting Xvfb with wine..."
export SteamAppId=1898300
xvfb-run --error-file=/tmp/xvfb-error.log wine $server_files/AskaServer.exe -nographics -batchmode -propertiesPath 'server properties.txt' 2>&1
