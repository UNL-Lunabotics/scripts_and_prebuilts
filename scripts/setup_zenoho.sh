#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# FILE:         setup_zenoh.sh
# AUTHOR:       Ella Moody <moodyellam@gmail.com>
# CREATED:      04-28-2026
# LAST EDITED:  04-28-2026
# DESCRIPTION:  This script sets up the zenoh daemon to run in the background.
#               Run this on the baremetal onboard computer.
# USAGE:        ./setup_zenoh.sh
# DEPENDS:      bash
# LICENSE:      Apache 2.0
# -----------------------------------------------------------------------------

SERVICE_FILE="/etc/systemd/system/zenoh-router.service"

echo "Creating systemd service file at $SERVICE_FILE..."

sudo tee $SERVICE_FILE > /dev/null << EOF
[Unit]
Description=Zenoh Router Daemon for ROS 2 Jazzy
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/bin/bash -c "source /opt/ros/jazzy/setup.bash && ros2 run rmw_zenoh_cpp rmw_zenohd"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling and starting zenoh-router.service..."
sudo systemctl enable zenoh-router.service
sudo systemctl start zenoh-router.service

echo "Zenoh router setup complete. Current Status:"
systemctl status zenoh-router.service --no-pager