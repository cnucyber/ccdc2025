#!/bin/bash

# USER ACTIVITY MONITORING SCRIPT

# Settings
LOG_FILE="/var/log/user_activity.log"       # Log file for all activities
ALERT_FILE="/var/log/user_alerts.log"       # Alert log file for suspicious activity
AUDIT_RULES_DIR="/etc/audit/rules.d"        # Directory for audit rules

# Ensure auditd is installed
echo "Checking if auditd is installed..."
if ! command -v auditctl &> /dev/null; then
    echo "Auditd is not installed. Installing auditd..."
    apt-get install auditd -y || { echo "Failed to install auditd. Exiting."; exit 1; }
else
    echo "Auditd is already installed."
fi

# ========================================
# 1. Track user login events
# ========================================
echo "Configuring audit rules to track user login events..."

# Create audit rule for login events
cat <<EOL > $AUDIT_RULES_DIR/user_login.rules
# Monitor user login events (e.g., SSH login)
-w /var/log/auth.log -p wa -k user_login_events
EOL

# Ensure proper file permissions for login rules
chmod 600 $AUDIT_RULES_DIR/user_login.rules
echo "Audit rule for user login events created and permissions set."

# ========================================
# 2. Monitor user creation and group changes
# ========================================
echo "Configuring audit rules to monitor user creation and group changes..."

# Append audit rules for user creation, password changes, and group modifications
cat <<EOL >> $AUDIT_RULES_DIR/user_creation.rules
# Monitor user creation (e.g., useradd, usermod) and group changes
-w /etc/passwd -p wa -k user_creation
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
EOL

# Ensure proper file permissions for user creation rules
chmod 600 $AUDIT_RULES_DIR/user_creation.rules
echo "Audit rule for user creation and group changes created and permissions set."

# ========================================
# 3. Restart auditd to apply rules
# ========================================
echo "Restarting auditd service to apply changes..."
systemctl restart auditd || { echo "Failed to restart auditd. Exiting."; exit 1; }
echo "auditd service restarted successfully."

# ========================================
# 4. Monitor user activity and suspicious events in real-time
# ========================================
echo "Monitoring user activity in real-time..."

# Use tail to monitor auth.log for suspicious activity and alert/log it
tail -f /var/log/auth.log | grep --line-buffered -E "sudo|useradd|passwd|groupadd|usermod|su" | while read -r line; do
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    # Log the suspicious activity to the log file
    echo "$timestamp - Suspicious activity detected: $line" >> $LOG_FILE
    
    # Send an alert to the alert log file
    echo "$timestamp - ALERT: $line" >> $ALERT_FILE

    # Print alert message to the terminal in red for emphasis
    echo -e "\e[1;31m[ALERT] Suspicious user activity detected!\e[0m"
    
    # Print a more descriptive message to the terminal
    echo "$timestamp - Activity: $line"
done &  # Run the tail process in the background

# ========================================
# 5. Final Notification
# ========================================
echo "User activity monitoring is now running in the background."
echo "Alerts will be displayed in the terminal and logged to $ALERT_FILE."
echo "Activity logs will be stored in $LOG_FILE."

# Provide the user with final confirmation
echo "User activity monitoring setup complete. You can now monitor logs in real-time."
