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
# 2. Install and configure AIDE (Advanced Intrusion Detection Environment)
# ========================================

echo "Installing and configuring AIDE (Advanced Intrusion Detection Environment)..."

# Install AIDE
apt install aide -y

# Define the AIDE configuration file path
AIDE_CONFIG_FILE="/etc/aide/aide.conf"

# Create log and alert directories for AIDE
mkdir -p /var/log/aide /var/log/aide/alerts

# Set permissions for the log directories
chmod 700 /var/log/aide
chmod 700 /var/log/aide/alerts
chown root:root /var/log/aide /var/log/aide/alerts

# Initialize AIDE database (this may take some time depending on the number of files on the system)
aideinit

# Move the newly created database to the correct location
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Configure AIDE to monitor important directories (customize this as needed)
cat <<EOL > $AIDE_CONFIG_FILE
# AIDE Configuration
database = /var/lib/aide/aide.db
database_out = /var/lib/aide/aide.db.new
gzip_dbout = yes
logfile = /var/log/aide/aide.log
report_url = file:///var/log/aide/alerts/aide_report.txt
# Monitor these directories
/etc
/bin
/sbin
/usr
/var
EOL

# Set file permissions for the AIDE configuration
chmod 600 $AIDE_CONFIG_FILE
chown root:root $AIDE_CONFIG_FILE

# Set up cron job to run AIDE check every 10 minutes
echo "*/10 * * * * root /usr/bin/aide --check >> /var/log/aide/aide.log 2>&1 && /usr/bin/aide --report >> /var/log/aide/alerts/aide_report.txt" > /etc/cron.d/aide

echo "AIDE installation and configuration completed!"


# ========================================
# 3. Install and configure rkhunter (Rootkit Hunter)
# ========================================

echo "Installing and configuring rkhunter (Rootkit Hunter)..."

# Install rkhunter
apt install rkhunter -y

# Prompt the user if they want to run rkhunter
read -p "Do you want to run Rootkit Hunter (rkhunter)? (y/n, default to n): " RUN_RK_HUNTER

# Default to 'n' if no input is given
RUN_RK_HUNTER=${RUN_RK_HUNTER:-n}

# If the user agrees to run rkhunter
if [[ "$RUN_RK_HUNTER" =~ ^[Yy]$ ]]; then
    # Update rkhunter database
    rkhunter --update

    # Run an initial rkhunter scan
    rkhunter --check --skip-keypress

    echo "rkhunter scan completed."
else
    echo "Skipping rkhunter scan."
fi

# Schedule rkhunter checks every 10 minutes using cron (if user agreed to run it)
if [[ "$RUN_RK_HUNTER" =~ ^[Yy]$ ]]; then
    echo "*/10 * * * * root rkhunter --check --skip-keypress" > /etc/cron.d/rkhunter
fi

echo "rkhunter installation and configuration completed!"

echo "Intrusion detection and prevention setup completed successfully!"
