#!/bin/bash

# ==========================================
# ULTIMATE SYSTEM-WIDE COMMAND MONITORING SUITE
# ==========================================
# This script:
# ✅ Logs every command from all users
# ✅ Monitors system-wide command execution via auditd, psacct, bash history
# ✅ Filters out its own execution to prevent self-logging
# ✅ Detects suspicious activity (privilege escalation, user modifications)
# ✅ Implements log rotation to prevent excessive file growth

# CONFIGURATION
LOG_DIR="/var/log/custom_monitor"
LOG_FILE="$LOG_DIR/user_activity.log"
ALERT_FILE="$LOG_DIR/user_alerts.log"
BASH_LOG_FILE="$LOG_DIR/bash_commands.log"
LOG_SIZE_LIMIT=1000000  # 1MB max log size before rotation

# Detect the username and UID of the user running this script
SCRIPT_USER=$(whoami)
SCRIPT_UID=$(id -u "$SCRIPT_USER")
SCRIPT_PID=$$

# ==========================================
# FUNCTION: Install Required Packages
# ==========================================
install_packages() {
    log_event "INFO" "Installing required packages..."

    # Install necessary packages if not already installed
    for pkg in auditd acct rsyslog wget; do
        if ! dpkg -l | grep -q "$pkg"; then
            sudo apt install -y "$pkg" || { log_event "ALERT" "Failed to install package: $pkg"; exit 1; }
            log_event "INFO" "Package $pkg installed successfully."
        else
            log_event "INFO" "Package $pkg is already installed."
        fi
    done
}

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
# FUNCTION: Set Up Logging Systems
# ==========================================
setup_logging() {
    log_event "INFO" "Setting up command monitoring systems..."

    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Install and configure auditd
    log_event "INFO" "Configuring auditd..."
    auditctl -D  # Remove previous audit rules
    auditctl -a always,exit -F arch=b64 -S execve -F auid!="$SCRIPT_UID" -k user_commands
    auditctl -a always,exit -F arch=b32 -S execve -F auid!="$SCRIPT_UID" -k user_commands
    log_event "INFO" "auditd is now monitoring command execution."

    # Install and enable process accounting (psacct/acct)
    log_event "INFO" "Configuring process accounting..."
    sudo systemctl enable acct
    sudo systemctl start acct
    log_event "INFO" "psacct/acct is now tracking process activity."

    # Configure bash history logging to syslog
    log_event "INFO" "Configuring bash command logging..."
    echo 'export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "' >> ~/.bashrc
    echo 'export PROMPT_COMMAND="history 1 | sed \"s/^ *[0-9]* *//\" | logger -t bash -p local6.info"' >> ~/.bashrc
    source ~/.bashrc
    echo "local6.* $BASH_LOG_FILE" | sudo tee -a /etc/rsyslog.d/bash.conf
    sudo systemctl restart rsyslog
    log_event "INFO" "Bash command logging enabled."
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
        for file in "$LOG_FILE" "$ALERT_FILE" "$BASH_LOG_FILE"; do
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
install_packages
setup_logging
log_event "INFO" "Starting full system-wide command monitoring..."
monitor_user_commands &  # Capture commands from ALL users except the script runner
monitor_suspicious_activity &  # Track privilege escalations and user modifications
rotate_logs &  # Prevent log overflow

log_event "INFO" "Monitoring system is now running in the background. Press Ctrl+C to stop."
wait
