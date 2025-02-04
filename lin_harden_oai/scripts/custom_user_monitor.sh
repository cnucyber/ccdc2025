#!/bin/bash

# USER ACTIVITY MONITORING SCRIPT

# Settings
LOG_FILE="/var/log/user_activity.log"
ALERT_FILE="/var/log/user_alerts.log"
AUDIT_RULES_DIR="/etc/audit/rules.d"

# Ensure auditd is installed
if ! command -v auditctl &> /dev/null; then
    echo "Auditd is not installed. Installing..."
    apt-get install auditd -y || { echo "Failed to install auditd"; exit 1; }
fi

# 1. Track user login events
echo "Tracking user login events..."
cat <<EOL > $AUDIT_RULES_DIR/user_login.rules
# Monitor user login events
-w /var/log/auth.log -p wa -k user_login_events
EOL

# 2. Monitor user creation and group changes
echo "Tracking user creation and group changes..."
cat <<EOL >> $AUDIT_RULES_DIR/user_creation.rules
# Monitor user creation and group changes
-w /etc/passwd -p wa -k user_creation
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
EOL

# Ensure proper file permissions for audit rule files
chmod 600 $AUDIT_RULES_DIR/user_login.rules
chmod 600 $AUDIT_RULES_DIR/user_creation.rules

# 3. Restart auditd to apply rules
echo "Restarting auditd service..."
systemctl restart auditd || { echo "Failed to restart auditd"; exit 1; }

# 4. Monitor user activity in real-time and alert on suspicious events
echo "Monitoring for suspicious activity..."

tail -f /var/log/auth.log | grep --line-buffered -E "sudo|useradd|passwd|groupadd|usermod|su" | while read -r line; do
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "$timestamp - Suspicious activity detected: $line" >> $LOG_FILE
    echo "$timestamp - ALERT: $line" >> $ALERT_FILE
    echo -e "\e[1;31m[ALERT] Suspicious user activity detected!\e[0m"
    echo "$timestamp - $line"
done &  # Run the tail process in the background

# Notify that monitoring has started
echo "User activity monitoring is now running in the background."
echo "Alerts will be displayed in the terminal and logged to $ALERT_FILE."
echo "Log file: $LOG_FILE"

# Exit the script so you can continue using the terminal
echo "User activity monitoring setup complete."
