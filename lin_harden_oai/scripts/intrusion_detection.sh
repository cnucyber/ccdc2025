#!/bin/bash

# INTRUSION DETECTION AND PREVENTION SETUP

echo "Starting intrusion detection and prevention setup..."

# ========================================
# 1. Install and configure Fail2ban
# ========================================

echo "Installing and configuring Fail2ban..."

# Install Fail2ban
apt update && apt install fail2ban -y

# Enable and start Fail2ban service
systemctl enable fail2ban
systemctl start fail2ban

# Ensure Fail2ban is configured to protect SSH (default configuration)
cat <<EOL > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 600
findtime = 600
maxretry = 3

[sshd]
enabled = true
EOL

# Restart fail2ban to apply changes
systemctl restart fail2ban

echo "Fail2ban installation and configuration completed!"


# ========================================
# 2. Install and configure AIDE
# ========================================

echo "Installing and configuring AIDE (Advanced Intrusion Detection Environment)..."

# Install AIDE
apt install aide -y

# Initialize AIDE
aideinit

# Schedule AIDE checks every 10 minutes using cron
echo "*/10 * * * * root /usr/bin/aide --check" > /etc/cron.d/aide

echo "AIDE installation and configuration completed!"


# ========================================
# 3. Install and configure rkhunter
# ========================================

echo "Installing and configuring rkhunter (Rootkit Hunter)..."

# Install rkhunter
apt install rkhunter -y

# Update rkhunter database
rkhunter --update

# Schedule rkhunter checks every 10 minutes using cron
echo "*/10 * * * * root rkhunter --check --skip-keypress" > /etc/cron.d/rkhunter

# Run an initial rkhunter scan
rkhunter --check --skip-keypress

echo "rkhunter installation and configuration completed!"


# ========================================
# 4. Install and configure OSSEC (Host-based IDS)
# ========================================

echo "Installing and configuring OSSEC (Host-based IDS)..."

# Install necessary dependencies
apt install -y curl unzip build-essential gcc make \
    libpcre2-dev zlib1g-dev libssl-dev libevent-dev \
    libsystemd-dev

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

echo "OSSEC installation and configuration completed!"


echo "Intrusion detection and prevention setup completed successfully!"
