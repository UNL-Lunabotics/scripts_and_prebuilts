#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# FILE:         setup_remote_platformio_uploads.sh
# AUTHOR:       Ella Moody <moodyellam@gmail.com>
# CREATED:      04-25-2026
# LAST EDITED:  04-25-2026
# DESCRIPTION:  This script basically just downloads the PlatformIO master list
#               of udev rules, triggers them, adds user to proper groups, and
#               that's it. It is intended to make remote pio run commands possible.
# USAGE:        sudo ./setup_remote_platformio_uploads.sh
# DEPENDS:      bash, sudo
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

set -euo pipefail

# This script needs to be run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run this script as root (with sudo)."
  exit 1
fi

curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules > /dev/null

udevadm control --reload-rules
udevadm trigger

TARGET_USER="${SUDO_USER:-$USER}"
sudo usermod -aG dialout $TARGET_USER
sudo usermod -aG plugdev $TARGET_USER

echo "[DONE] Setup complete. Log out and log back in for group changes to take effect."