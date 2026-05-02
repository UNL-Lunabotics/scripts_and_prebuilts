#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# FILE:         build_vm.sh
# AUTHOR:       Aiden Kimmerling <apkimmerling@gmail.com>
# CREATED:      09-01-2025
# LAST EDITED:  04-30-2026
# DESCRIPTION:  Builds a ROS2-ready Ubuntu Desktop virtual machine using UTM,
#               a hypervisor for macOS. It is used in tandem with an autoinstall
#               file --- used for installing all packages --- and a template,
#               which is used to configure the virtual machine settings. It is
#               intended to only be used for macOS users wanting to develop for
#                ROS2 on their own laptops, and will not work for other platforms.
#               Additionally, this script requires a newer Mac (2019+), as it assumes 
#               an ARM-based processor (M-Series MacBooks). Finally, it requires for
#               brew to be installed, along with some utility cli-tools.
# USAGE:        ./build_vm.sh [options] --- All [options] are NOT required and are optional.
# OPTIONS:      ./build_vm.sh [Ubuntu LTS Codename] <vm-name> <password> [Display Resolution]
#                             [CPU Cores] [Memory in MB] [Disk Size in GB] [Network Interface]
# DEPENDS:      macOS, brew, bash, openssl, curl, cdrtools, qemu-img, UTM
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

set -euo pipefail

UBUNTU_CODENAME="${1:-noble}"

# Get the Ubuntu Version (i.e. 24.04) from the $UBUNTU_CODENAME
RELEASE=$(curl -fsSL https://changelogs.ubuntu.com/meta-release | awk -v codename="${UBUNTU_CODENAME}" '/^Dist:/ { d=$2 } /^Version:/ && d == codename { print $2; exit }')

VM_NAME="${2:-Ubuntu ${RELEASE} ARM64}"
PASSWORD="${3:-}"
DISP_RES="${4:-3456x2160}"
CPU_CORES=${5:-0}
MEMORY_MB=${6:-4096}
DISK_GB=${7:-20}
NETWORK_INTERFACE="${8:-enp0s1}"

DISK_UUID=$(uuidgen)
SEED_UUID=$(uuidgen)
INSTALLER_UUID=$(uuidgen)

IMAGE_URL="https://cdimage.ubuntu.com/releases/${RELEASE}/release/ubuntu-${RELEASE}-live-server-arm64.iso"

# If a password is provided, create a hash. Otherwise, leave blank
PASS_HASH=$([ -z "$PASSWORD" ] && echo "" || openssl passwd -6 "$PASSWORD")

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# Find ROS Codename from rosdistro. Goes through each distribution's yaml file
# and finds the corresponding 'ubuntu: ' tag, and cross-references it with $UBUNTU_CODENAME
printf "\n=== Finding the ROS Codename Corresponding to Ubuntu ${UBUNTU_CODENAME} ===\n"

ROS_CODENAME=$(curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/index.yaml \
| grep -oE '[a-z0-9_-]+/distribution.yaml' \
| sed 's#/distribution.yaml##' \
| while read -r distro; do
    curl -fsSL "https://raw.githubusercontent.com/ros/rosdistro/master/$distro/distribution.yaml" \
    | grep -A5 -i 'ubuntu' \
    | grep -qi -- "$UBUNTU_CODENAME" && { echo $distro; exit 0; }
  done)

mkdir -p isos

# UTM requires all Disks to be in the /Data folder
mkdir -p "${VM_NAME}.utm/Data"

# ------------------------------------------------------------------
# Download Ubuntu Live Server Image
# ------------------------------------------------------------------
printf "\n=== Downloading Ubuntu ${RELEASE} Live Server Image ===\n"

ISO_NAME="ubuntu-${UBUNTU_CODENAME}-arm.iso"

if ! [ -e "isos/${ISO_NAME}" ]
then
  curl -L "$IMAGE_URL" -o "isos/${ISO_NAME}"
fi

cp "isos/${ISO_NAME}" "${VM_NAME}.utm/Data/installer.iso"

printf "\n=== Creating User Disk ===\n"
qemu-img create -f qcow2 "${VM_NAME}.utm/Data/main.qcow2" "${DISK_GB}G"

# ------------------------------------------------------------------
# Make the Seed Image
# ------------------------------------------------------------------
printf "\n=== Making the Seed Image ===\n\n"

# Subsitute template variables for real values
export DISP_RES PASS_HASH NETWORK_INTERFACE UBUNTU_CODENAME ROS_CODENAME ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
envsubst < "config/autoinstall.yaml" > "${WORKDIR}/user-data"

# Needed to make the seed image but don't need configuration
echo "hostname: ubuntu" > "${WORKDIR}/meta-data"
echo "" > "${WORKDIR}/network-config"

# Makes the seed image
mkisofs -output "${VM_NAME}.utm/Data/seed.qcow2" -volid cidata -rational-rock -joliet "${WORKDIR}/user-data" "${WORKDIR}/meta-data" "${WORKDIR}/network-config"

# ------------------------------------------------------------------
# Generate the UTM config.plist from a template
# ------------------------------------------------------------------
printf "\n=== Generating config.plist ===\n"
export INSTALLER_UUID DISK_UUID SEED_UUID DISK_NAME="${DISK_UUID}.qcow2" \
       CPU_CORES="$CPU_CORES" MEMORY_MB="$MEMORY_MB" \
       MAC_ADDRESS=$(openssl rand -hex 6 | sed 's/../&:/g; s/:$//' | tr 'a-f' 'A-F') \
       VM_NAME="$VM_NAME"

# Subsitute template variables for real values
envsubst < "config/template.plist" > "${VM_NAME}.utm/config.plist"

printf "\nUTM template ready: $VM_NAME.utm\n\n"