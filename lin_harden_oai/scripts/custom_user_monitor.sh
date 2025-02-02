#!/bin/bash

# USER ACTIVITY MONITORING SCRIPT

# Settings
LOG_FILE="/var/log/user_activity.log"
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

# 4. Check for suspicious user activity and log it
echo "Monitoring for suspicious activity..."

# Run tail in the background to continuously monitor logs
tail -f /var/log/auth.log | grep --line-buffered -E "sudo|useradd" | while read -r line; do
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $line" >> $LOG_FILE
done &  # Run the tail process in the background

# Optionally, you can add a log message to confirm the background process is running
echo "User activity monitoring is now running in the background. Logs are being written to $LOG_FILE."

# Exit the script so you can run other commands
echo "User activity monitoring setup complete. You can now use the terminal."
