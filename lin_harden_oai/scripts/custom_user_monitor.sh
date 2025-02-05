#!/bin/bash

# ==========================================
# SYSTEM-WIDE USER COMMAND MONITORING & SECURITY AUDITING
# ==========================================
# This script monitors:
# - Commands executed by ALL users except the script's user
# - User logins (failed/successful)
# - Unauthorized user creations/modifications
# - Suspicious user activity (sudo, passwd changes, privilege escalation)
# - Log rotation to prevent excessive log size

# CONFIGURATION
LOG_FILE="/var/log/user_activity.log"      # General activity log
ALERT_FILE="/var/log/user_alerts.log"      # Suspicious activity alerts
MONITOR_FILE="/var/log/auth.log"           # Authentication log for tracking logins
ENABLE_COMMAND_ECHO=true                   # Enable/Disable real-time command logging
LOG_SIZE_LIMIT=1000000                      # 1MB max log size before rotation

# Detect the username and UID of the user running this script
SCRIPT_USER=$(whoami)
SCRIPT_UID=$(id -u "$SCRIPT_USER")
SCRIPT_PID=$$  # Capture the script's own process ID

# Ensure required commands exist
for cmd in auditctl ausearch tail awk grep stat; do
    command -v "$cmd" &> /dev/null || { echo "Error: $cmd is not installed. Install it before running."; exit 1; }
done

# ==========================================
# FUNCTION: Log messages with timestamps
# ==========================================
log_event() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # Print to terminal with color
    case "$level" in
        INFO) echo -e "\e[1;34m[$timestamp] [INFO] $message\e[0m" ;;
        ALERT) echo -e "\e[1;31m[$timestamp] [ALERT] $message\e[0m" ;;
        COMMAND) echo -e "\e[1;32m[$timestamp] [COMMAND] $message\e[0m" ;;
        *) echo -e "\e[1;33m[$timestamp] [UNKNOWN] $message\e[0m" ;;
    esac

    # Write to log files
    echo "$timestamp [$level] $message" >> "$LOG_FILE"
    [[ "$level" == "ALERT" ]] && echo "$timestamp [$level] $message" >> "$ALERT_FILE"
}

# ==========================================
# FUNCTION: Configure Audit Rules
# ==========================================
configure_audit_rules() {
    log_event "INFO" "Configuring audit rules to exclude $SCRIPT_USER (UID: $SCRIPT_UID)..."
    
    # Remove previous audit rules
    auditctl -D
    
    # Set audit rules to capture all commands except from the script user
    auditctl -a always,exit -F arch=b64 -S execve -F auid!="$SCRIPT_UID" -k user_commands
    auditctl -a always,exit -F arch=b32 -S execve -F auid!="$SCRIPT_UID" -k user_commands

    log_event "INFO" "Audit rules configured."
}

# ==========================================
# FUNCTION: Monitor User Commands (Excluding This Script)
# ==========================================
monitor_user_commands() {
    log_event "INFO" "Monitoring commands from all users except $SCRIPT_USER..."

    tail -Fn0 /var/log/audit/audit.log | while read -r line; do
        if echo "$line" | grep -q "execve"; then
            pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+' | head -1)

            # Ignore if PID matches the script's process
            if [[ "$pid" == "$SCRIPT_PID" ]]; then
                continue
            fi

            timestamp=$(date +'%Y-%m-%d %H:%M:%S')
            user_id=$(echo "$line" | grep -oP 'uid=\K[0-9]+' | head -1)
            command=$(echo "$line" | grep -oP 'a0="[^"]+"' | cut -d '"' -f2)

            username=$(getent passwd "$user_id" | cut -d: -f1)
            [[ -z "$username" ]] && username="Unknown"

            log_event "COMMAND" "User [$username] executed command: $command"
        fi
    done
}

# ==========================================
# FUNCTION: Monitor Suspicious User Activity
# ==========================================
monitor_suspicious_activity() {
    log_event "INFO" "Monitoring suspicious user activity..."
    
    tail -Fn0 "$MONITOR_FILE" | grep --line-buffered -E "sudo|useradd|passwd|groupadd|usermod" | while read -r line; do
        timestamp=$(date +'%Y-%m-%d %H:%M:%S')
        log_event "ALERT" "Suspicious activity detected: $line"
    done
}

# ==========================================
# FUNCTION: Rotate Logs When Exceeding Size Limit
# ==========================================
rotate_logs() {
    while true; do
        sleep 3600  # Check every hour
        for file in "$LOG_FILE" "$ALERT_FILE"; do
            if [[ -f "$file" ]] && [[ $(stat --format=%s "$file") -ge $LOG_SIZE_LIMIT ]]; then
                mv "$file" "$file.old"
                touch "$file"
                log_event "INFO" "Rotated log file: $file"
            fi
        done
    done
}

# ==========================================
# FUNCTION: Cleanup and Stop Monitoring Gracefully
# ==========================================
cleanup() {
    log_event "INFO" "Stopping monitoring and cleaning up..."
    auditctl -D  # Remove audit rules
    exit 0
}

trap cleanup SIGINT SIGTERM

# ==========================================
# START MONITORING FUNCTIONS IN BACKGROUND
# ==========================================
log_event "INFO" "Starting full system-wide user command monitoring..."
configure_audit_rules
monitor_user_commands &  # Capture commands from ALL users except the script runner
monitor_suspicious_activity &  # Track privilege escalations and user modifications
rotate_logs &  # Prevent log overflow

log_event "INFO" "Monitoring system is now running in the background. Press Ctrl+C to stop."
wait
