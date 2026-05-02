#!/bin/bash

# -----------------------------------------------------------------------------
# FILE:         connect_mini_pc_vnc.sh
# AUTHOR:       Aiden Kimmerling <apkimmerling@gmail.com>
# CREATED:      01-01-2026
# LAST EDITED:  04-30-2026
# DESCRIPTION:  An (incomplete) script to connect to a Mini PC through SSH and VNC.
#               Intended to be used by SSH-ing into the Mini PC, then running this
#               script. Creates a new user on the Mini PC and sets up a vncserver
#               to access a GUI through a VNC connection.
# USAGE:        sudo ./connect_mini_pc_vnc.sh [user]
# DEPENDS:      bash, sudo, su, passwd, adduser, vncserver
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

user="$1"
START_PORT=59

if [ -z "$user" ]; then
    echo "Please enter a user name"
    exit
fi

if [ "$(id -u)" != "0" ]; then
    echo "Run as sudo: 'sudo ./connect_mini_pc_vnc.sh'"
    exit
fi

find_user=$(getent passwd "$user")
if [ -n "$find_user" ]; then
    echo "User exists. Please choose a different user"
    exit
fi

echo "Adding user $user"

adduser --disabled-password --gecos "" "$user"

find_single_port() {
    local port="$1"
    result=$(ss -ltn | grep $port)

    if [[ -n "$result" ]]; then
        return 0 # true
    else
        return 1 # false
    fi
}

find_all_ports() {
    for i in {00..99}; do
        CURR_PORT="$START_PORT$i" # contatenates 59 with i -> 5900, 5901, etc.
        if ! find_single_port "$CURR_PORT"; then
            echo "$CURR_PORT"
            return 0
        fi
    done

    return 1
}

port=$(find_all_ports)

echo "Found port $port"

on_exit() {
    printf "\n====Deleting user $user====\n\n"

    pkill -u "$user"
    deluser --remove-home "$user"
    rm -rf "/home/$user"
}

# When script gets exited, do the `on_exit` function
trap on_exit EXIT

printf "\n====Your VNC instance is on port $port====\n\n"

# The command to start vnc
su - "$user" -c "vncserver -localhost no -rfbport $port -xstartup /usr/bin/startxfce4 -SecurityTypes NONE --I-KNOW-THIS-IS-INSECURE -fg" "$user"