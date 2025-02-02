#!/bin/bash

# OSSEC INSTALLATION SCRIPT (Non-Interactive)

echo "Starting OSSEC automated installation..."

# Update package list
apt update

# Install necessary dependencies
apt install -y curl unzip build-essential gcc make libpcre2-dev

# Download OSSEC installer
curl -L -o /tmp/ossec.tar.gz https://github.com/ossec/ossec-hids/archive/refs/tags/3.7.0.tar.gz

# Extract the installer
tar -xvzf /tmp/ossec.tar.gz -C /tmp/

# Change directory to OSSEC source
cd /tmp/ossec-hids-3.7.0/

# Create a PRELOADED-VARS file to provide non-interactive inputs
cat <<EOF > /tmp/PRELOADED-VARS.conf
USER_LANGUAGE="en"
USER_INSTALL_TYPE="server"
USER_DIR="/var/ossec"
USER_ENABLE_EMAIL="no"
USER_ENABLE_ACTIVE_RESPONSE="yes"
USER_ENABLE_SYSCHECK="yes"
USER_ENABLE_ROOTCHECK="yes"
USER_ENABLE_FIREWALLDROP="yes"
EOF

# Run the OSSEC installation with preloaded answers
export PRELOADED_VARS="/tmp/PRELOADED-VARS.conf"
./install.sh

# Enable and start OSSEC service
systemctl enable ossec
systemctl start ossec

echo "OSSEC installation completed successfully!"
