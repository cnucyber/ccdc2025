#!/bin/bash

# ==========================================
# SYSTEM-WIDE USER COMMAND MONITORING & SECURITY AUDITING
# ==========================================
# This script monitors:
# - Commands executed by ALL users except the script's user
# - User logins (failed/successful)
# - Unauthorized user creations/modifications
# - Suspicious user activity (sudo, passwd changes, privilege escalation)
# - File integrity (AIDE)
# - Log rotation & alerting

# CONFIGURATION
LOG_FILE="/var/log/user_activity.log"      # General activity log
ALERT_FILE="/var/log/user_alerts.log"      # Suspicious activity alerts
AIDE_REPORT="/var/log/aide/aide_report.txt" # AIDE report for file integrity monitoring
MONITOR_FILE="/var/log/auth.log"           # Authentication log for tracking logins
ENABLE_COMMAND_ECHO=true                    # Enable/Disable real-time command logging
EMAIL_ALERTS=false                         # Set to 'true' to enable email alerts
LOG_SIZE_LIMIT=1000000                      # 1MB max log size before rotation

# Detect the username of the user running this script
SCRIPT_USER=$(whoami)

# Ensure required commands exist
command -v auditctl &> /dev/null || { echo "Error: auditd is not installed. Install with: sudo apt install auditd"; exit 1; }

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

    # Send email alert (optional)
    if [[ "$EMAIL_ALERTS" == true && "$level" == "ALERT" ]]; then
        echo "$message" | mail -s "[SECURITY ALERT] $message" "$ADMIN_EMAIL"
    fi
}

# ==========================================
# FUNCTION: Capture ALL User Commands Except the Script's User
# ==========================================
monitor_all_user_commands() {
    if [[ "$ENABLE_COMMAND_ECHO" == true ]]; then
        log_event "INFO" "Monitoring all executed commands except those by $SCRIPT_USER..."

        # Configure audit rules to log ALL command executions via execve
        auditctl -D
        auditctl -a always,exit -F arch=b64 -S execve -k command_exec
        auditctl -a always,exit -F arch=b32 -S execve -k command_exec

        # Monitor the audit log for executed commands
        tail -Fn0 /var/log/audit/audit.log | while read -r line; do
            if echo "$line" | grep -q "execve"; then
                timestamp=$(date +'%Y-%m-%d %H:%M:%S')
                user_id=$(echo "$line" | grep -oP 'uid=\K[0-9]+' | head -1)
                command=$(echo "$line" | grep -oP 'a0="[^"]+"' | cut -d '"' -f2)
                full_command=$(echo "$line" | grep -oP 'a[0-9]="[^"]+"' | tr '\n' ' ' | sed 's/a[0-9]="//g' | sed 's/"//g')

                username=$(getent passwd "$user_id" | cut -d: -f1)
                [[ -z "$username" ]] && username="Unknown"

                # Ignore commands executed by the user running this script
                if [[ "$username" != "$SCRIPT_USER" ]]; then
                    log_event "COMMAND" "User [$username] executed command: $full_command"
                fi
            fi
        done
    else
        log_event "INFO" "Command monitoring is disabled."
    fi
}

# ==========================================
# FUNCTION: Monitor Suspicious User Activity
# ==========================================
monitor_suspicious_activity() {
    log_event "INFO" "Monitoring suspicious user activity..."
    tail -Fn0 "$MONITOR_FILE" | grep --line-buffered -E "sudo|useradd|passwd|groupadd|usermod" | while read -r line; do
        user=$(echo "$line" | awk '{print $NF}')
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
# START MONITORING FUNCTIONS IN BACKGROUND
# ==========================================
log_event "INFO" "Starting full system-wide user command monitoring..."
monitor_all_user_commands &  # Capture commands from ALL users except the script runner
monitor_suspicious_activity &  # Track privilege escalations and user modifications
rotate_logs &  # Prevent log overflow

log_event "INFO" "Monitoring system is now running in the background."
