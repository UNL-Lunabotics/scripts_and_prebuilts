#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# FILE:         configure_wifi_priority.sh
# AUTHOR:       Ella Moody <moodyellam@gmail.com>
# CREATED:      04-25-2026
# LAST EDITED:  05-10-2026
# DESCRIPTION:  This script is intended to 1. configure the wifi network priority of
#               the onboard computer to prefer Team_##, Team_##_5g, and then eduroam.
#               Then, 2. create a daemon that, if on eduroam, checks every interval to see
#               if Team_## is available and connect to that instead, then Team_##_5g.
#               This script requires that the computer has already connected to both and has the
#               user/password saved. This script will need to be manually edited and
#               ran again if the SSID of the network changes. It also configs antenna.
# USAGE:        sudo ./configure_wifi_priority.sh
# DEPENDS:      bash, sudo
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

set -euo pipefail

PRIMARY_SSID="Team_37"
SECONDARY_SSID="Team_37_5g"
TERTIARY_SSID="eduroam"
CHECK_INTERVAL=30

# Script needs to run as root
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run this script as root (with sudo)."
  exit 1
fi


# update the NetworkManager priorities
echo "[OK] Updating NetworkManager Priorities to favor team SSID..."
if nmcli connection show | grep -q "$PRIMARY_SSID"; then
    nmcli connection modify "$PRIMARY_SSID" connection.autoconnect yes connection.autoconnect-priority 100
    nmcli connection modify "$PRIMARY_SSID" connection.interface-name "" 802-11-wireless.mac-address ""
    echo "[OK] Set $PRIMARY_SSID priority to 100"
else
    echo "[WARNING] Connection profile for $PRIMARY_SSID not found. Please connect to it manually first."
fi

echo "[OK] Updating NetworkManager Priorities to favor secondary SSID..."
if nmcli connection show | grep -q "$SECONDARY_SSID"; then
    nmcli connection modify "$SECONDARY_SSID" connection.autoconnect yes connection.autoconnect-priority 99
    nmcli connection modify "$SECONDARY_SSID" connection.interface-name "" 802-11-wireless.mac-address ""
    echo "[OK] Set $SECONDARY_SSID priority to 99"
else
    echo "[WARNING] Connection profile for $SECONDARY_SSID not found. Please connect to it manually first."
fi

echo "[OK] Updating NetworkManager Priorities to favor tertiary SSID..."
if nmcli connection show | grep -q "$TERTIARY_SSID"; then
    nmcli connection modify "$TERTIARY_SSID" connection.autoconnect yes connection.autoconnect-priority 98
    nmcli connection modify "$TERTIARY_SSID" connection.interface-name "" 802-11-wireless.mac-address ""
    echo "[OK] Set $TERTIARY_SSID priority to 98"
else
    echo "[WARNING] Connection profile for $TERTIARY_SSID not found. Please connect to it manually first."
fi

# Part 2. write the daemon script that will run in the background
echo "[OK] Creating the daemon script..."
MONITOR_SCRIPT="/usr/local/bin/wifi-priority-monitor.sh"


# Literally write a whole other script in this script it's getting funky
cat << 'EOF' > "$MONITOR_SCRIPT"
#!/bin/bash

PRIMARY="REPLACE_PRIMARY"
SECONDARY="REPLACE_SECONDARY"
INTERVAL=REPLACE_INTERVAL

while true; do
    # Get the name of the currently active Wi-Fi connection
    ACTIVE_CONNECTION=$(nmcli -t -f NAME,TYPE connection show --active | grep 802-11-wireless | cut -d: -f1)

    # Is the external antenna connected? If yes, connect to that and disable internal card. If no, use internal card
    ANTENNA_SERIAL=$(nmcli device | grep wlx | cut -d " " -f1 | grep -v p2p)
    if [[ -n $ANTENNA_SERIAL ]]; then
        echo "entered yes antenna if"
        ANTENNA_STATUS=$(nmcli device | grep wlx | grep -v p2p | tr -s ' ' | cut -d " " -f3)
        if [[ $ANTENNA_STATUS != "connecting" && $ANTENNA_STATUS != "connected" ]]; then
            tailscale down
            nmcli device set wlp3s0 managed no
            systemctl stop tailscaled
            nmcli device wifi connect $ACTIVE_CONNECTION ifname $ANTENNA_SERIAL
        fi
    else
        if [ $(nmcli device | grep wlp3s0 | grep -v p2p | tr -s ' ' | cut -d " " -f3) == "unmanaged" ]; then
            nmcli device set wlp3s0 managed yes
            systemctl start tailscaled
            tailscale up
        fi
    fi

    # If we are NOT connected to the primary network...
    if [ "$ACTIVE_CONNECTION" != "$PRIMARY" ]; then
        # Force a Wi-Fi scan and check if the primary network is in range
        if nmcli -t -f ssid dev wifi list | grep -q "^${PRIMARY}$"; then
            echo "$(date): $PRIMARY found! Switching from $ACTIVE_CONNECTION..."
            nmcli connection up "$PRIMARY"
            continue
        fi

        # If we are not connected to the secondary network
        if [ "$ACTIVE_CONNECTION" != "$SECONDARY" ]; then
            # Force a Wi-Fi scan and check if the secondary network is in range
            if nmcli -t -f ssid dev wifi list | grep -q "^${SECONDARY}$"; then
                echo "$(date): $SECONDARY found! Switching from $ACTIVE_CONNECTION..."
                nmcli connection up "$SECONDARY"
            fi
        fi
    fi

    sleep $INTERVAL
done
EOF

# Inject variables into the daemon script
sed -i "s/REPLACE_PRIMARY/$PRIMARY_SSID/g" "$MONITOR_SCRIPT"
sed -i "s/REPLACE_SECONDARY/$SECONDARY_SSID/g" "$MONITOR_SCRIPT"
sed -i "s/REPLACE_INTERVAL/$CHECK_INTERVAL/g" "$MONITOR_SCRIPT"
chmod +x "$MONITOR_SCRIPT"
echo "[OK] Daemon script created at $MONITOR_SCRIPT"


# Turn this whole other monitor script into a daemon service
echo "[OK] Turning script in Daemon..."
SERVICE_FILE="/etc/systemd/system/wifi-priority-monitor.service"


cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Continuous WiFi Priority Monitor
After=network.target NetworkManager.service
Wants=NetworkManager.service

[Service]
Type=simple
ExecStart=$MONITOR_SCRIPT
Restart=on-failure
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "[OK] Systemd service created."


# Start service now
echo "[OK] Starting the Daemon service..."
systemctl daemon-reload
systemctl enable wifi-priority-monitor.service
systemctl restart wifi-priority-monitor.service
echo "[OK] Service started!"


echo "DONE SUCCESS"