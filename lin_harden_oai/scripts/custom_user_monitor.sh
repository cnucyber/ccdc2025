#!/bin/bash

# CUSTOM USER MONITORING SCRIPT
# This script integrates with AIDE to monitor suspicious user activity, including unauthorized user creation or modification of critical system files.

# Settings
LOG_FILE="/var/log/user_activity.log"       # Log file for all activities
ALERT_FILE="/var/log/user_alerts.log"       # Alert log file for suspicious activity
MONITOR_DIR="/var/log"                      # Directory to monitor logs
MONITOR_FILE="$MONITOR_DIR/auth.log"        # Log file to monitor for activity
THRESHOLD_FAILED_LOGINS=5                   # Number of failed logins before alerting
ALERT_THRESHOLD_TIME=60                     # Time period (in seconds) for checking login attempts
AIDE_REPORT="/var/log/aide/aide_report.txt"  # Location of AIDE's report

# Ensure necessary log files exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Created log file: $LOG_FILE"
fi

if [ ! -f "$ALERT_FILE" ]; then
    touch "$ALERT_FILE"
    echo "Created alert file: $ALERT_FILE"
fi

# ========================================
# 1. Monitor for Failed Login Attempts
# ========================================
echo "Starting to monitor failed login attempts..."

failed_logins() {
    # Monitor failed login attempts and log alerts if exceeded threshold
    grep "Failed password" "$MONITOR_FILE" | awk '{print $(NF-3)}' | sort | uniq -c | awk -v threshold="$THRESHOLD_FAILED_LOGINS" '$1 >= threshold' | while read -r count ip; do
        timestamp=$(date +'%Y-%m-%d %H:%M:%S')
        echo "$timestamp - ALERT: Multiple failed login attempts from $ip ($count attempts)" >> "$ALERT_FILE"
        echo -e "\e[1;31m[ALERT] Multiple failed login attempts from $ip ($count attempts)\e[0m"
    done
}

# ========================================
# 2. Monitor Suspicious User Activity Using AIDE Reports
# ========================================
echo "Starting to monitor suspicious user activity..."

monitor_suspicious_user_activity() {
    # Monitor the AIDE report for unauthorized changes to critical files
    tail -f "$AIDE_REPORT" | while read -r line; do
        # Look for suspicious file changes (e.g., passwd, shadow, etc.)
        if echo "$line" | grep -qE '(/etc/passwd|/etc/shadow|/etc/group|/etc/sudoers)'; then
            timestamp=$(date +'%Y-%m-%d %H:%M:%S')
            echo "$timestamp - ALERT: Suspicious activity detected: $line" >> "$ALERT_FILE"
            echo -e "\e[1;33m[ALERT] Suspicious file modification detected: $line\e[0m"
            echo "$timestamp - Suspicious file modification detected: $line"
        fi
    done
}

# ========================================
# 3. Monitor User Creation and Modifications
# ========================================
echo "Starting to monitor user creation and modifications..."

monitor_user_creation() {
    # Monitor user creation and modifications in the log file
    tail -f "$MONITOR_FILE" | grep --line-buffered -E "useradd|usermod|groupadd|passwd" | while read -r line; do
        timestamp=$(date +'%Y-%m-%d %H:%M:%S')
        
        # Log user modifications or creation
        echo "$timestamp - User modification detected: $line" >> "$LOG_FILE"
        echo -e "\e[1;34m[INFO] User modification detected: $line\e[0m"
    done
}

# ========================================
# 4. Apply User Activity Monitoring in Parallel
# ========================================
echo "User activity monitoring is now running in parallel for failed login attempts, suspicious activity, and user modifications..."

failed_logins &  # Run failed login monitoring in the background
monitor_suspicious_user_activity &  # Run suspicious user activity monitoring in the background
monitor_user_creation &  # Run user creation/modification monitoring in the background

# ========================================
# 5. Monitor and Clean Up Old Logs Periodically
# ========================================
cleanup_old_logs() {
    # Clean up alert and log files periodically to avoid large file sizes
    MAX_LOG_SIZE=1000000  # 1MB in bytes

    while true; do
        sleep 3600  # Every hour

        log_size=$(stat --format=%s "$LOG_FILE")
        alert_size=$(stat --format=%s "$ALERT_FILE")

        if [ "$log_size" -gt "$MAX_LOG_SIZE" ]; then
            echo "Log file exceeded size limit, rotating log..."
            mv "$LOG_FILE" "$LOG_FILE.old"
            touch "$LOG_FILE"
            echo "Log file rotated. Previous log saved as $LOG_FILE.old."
        fi

        if [ "$alert_size" -gt "$MAX_LOG_SIZE" ]; then
            echo "Alert file exceeded size limit, rotating alert log..."
            mv "$ALERT_FILE" "$ALERT_FILE.old"
            touch "$ALERT_FILE"
            echo "Alert log rotated. Previous log saved as $ALERT_FILE.old."
        fi
    done
}

# ========================================
# 6. Final Notification
# ========================================
echo "User activity monitoring setup complete."
echo "Monitoring started in the background for failed login attempts, suspicious activity, user modifications, and log rotation."

# Start log cleanup in the background
cleanup_old_logs &
