#!/bin/bash

# INTRUSION DETECTION AND PREVENTION

echo "Starting intrusion detection and prevention setup..."

# ========================================
# 1. Install and configure Fail2ban
# ========================================

echo "Installing and configuring Fail2ban..."

# Install Fail2ban
apt install fail2ban -y

# Enable and start Fail2ban service
systemctl enable fail2ban
systemctl start fail2ban

# Ensure Fail2ban is configured to protect SSH (default configuration)
echo "[DEFAULT]" >> /etc/fail2ban/jail.local
echo "bantime = 600" >> /etc/fail2ban/jail.local
echo "findtime = 600" >> /etc/fail2ban/jail.local
echo "maxretry = 3" >> /etc/fail2ban/jail.local
echo "[sshd]" >> /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local

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
echo "*/10 * * * * root rkhunter --check" > /etc/cron.d/rkhunter

# Run an initial rkhunter scan
rkhunter --check

echo "rkhunter installation and configuration completed!"


# ========================================
# 4. Install and configure OSSEC (Host-based IDS)
# ========================================

echo "Installing and configuring OSSEC (Host-based IDS)..."

# Install OSSEC
apt install ossec-hids -y

# Enable and start OSSEC service
systemctl enable ossec
systemctl start ossec

# OSSEC is configured by default to monitor system logs for suspicious activity.
# No email alerts configured as per user request.

echo "OSSEC installation and configuration completed!"


echo "Intrusion detection and prevention setup completed successfully!"

