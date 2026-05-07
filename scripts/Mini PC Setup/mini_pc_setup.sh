#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# FILE:         mini_pc_setup.sh
# AUTHOR:       Aiden Kimmerling <apkimmerling@gmail.com>
# CREATED:      05-02-2026
# LAST EDITED:  05-02-2026
# DESCRIPTION:  Builds a ROS2-ready Ubuntu Desktop virtual machine using UTM,

# DESCRIPTION:  Builds a ROS2-ready Ubuntu Desktop autoinstall files for imaging
#               a new Mini PC, meant to be used with Ventoy. Prompts the user 
#               for the ISO name, Ubuntu and ROS2 codename, and a password. It 
#               then generates the required files for Ventoy, ready to be plugged
#               into the Mini PC and imaged.
# USAGE:        ./mini_pc_setup.sh
# DEPENDS:      bash, envsubst, openssl
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

set -euo pipefail

# Prompt for ISO name
read -rp "Enter ISO image name (e.g., ubuntu-24.04-desktop-amd64.iso): " ISO_NAME

# Prompt for Ubuntu and ROS2 codename
read -rp "Enter Ubuntu codename (e.g., noble, jammy): " UBUNTU_CODENAME
read -rp "Enter ROS2 codename (e.g., jazzy, humble): " ROS_CODENAME

# Prompt for password (hidden)
read -rsp "Enter password: " PASSWORD
echo

# Handle empty password case
if [[ -z "$PASSWORD" ]]; then
    PASS_HASH=""
else
    PASS_HASH=$(openssl passwd -6 "$PASSWORD")
fi

# Set up autoinstall
## Export variables for envsubst
export UBUNTU_CODENAME
export ROS_CODENAME
export PASS_HASH
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')

## Input/output files
AUTOINSTALL_TEMPLATE="ventoy-configuration/scripts/ubuntu-autoinstall-template.yaml"
AUTOINSTALL_OUTPUT="ventoy-configuration/scripts/ubuntu-autoinstall.yaml"

## Substitute variables
envsubst < "$AUTOINSTALL_TEMPLATE" > "$AUTOINSTALL_OUTPUT"

echo "Generated $AUTOINSTALL_OUTPUT"

# Set up ventoy config
export ISO_NAME

VENTOY_TEMPLATE="ventoy-configuration/ventoy/ventoy-template.json"
VENTOY_OUTPUT="ventoy-configuration/ventoy/ventoy.json"

envsubst < "$VENTOY_TEMPLATE" > "$VENTOY_OUTPUT"

echo "Generated $VENTOY_OUTPUT"