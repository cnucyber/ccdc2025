#!/bin/bash

# Security Monitoring Script for Network Activity, Unauthorized Access, Malicious Processes,
# File Integrity, and Brute-Force Attacks.

echo "Starting comprehensive security monitoring..."

# ========================================
# 1. Suspicious Network Activity Detection and Response
# ========================================
echo "Starting network activity monitoring..."

# Define variables
LOG_FILE="/var/log/auth.log"            # Authentication log file
BLOCK_LIST="/tmp/suspicious_ips.txt"    # File to store suspicious IPs

# Detect failed SSH login attempts (port scanning or brute-force)
grep "Failed password" $LOG_FILE | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 > 5' > $BLOCK_LIST

# Block IPs with excessive failed login attempts
while read IP; do
    echo "Blocking IP address $IP due to suspicious network activity..."

    # Block the IP address using iptables
    iptables -A INPUT -s $IP -j DROP

    # Send an alert about the blocked IP
    echo "Blocked IP address $IP for suspicious network activity."
done < $BLOCK_LIST

echo "Suspicious network activity detection and response completed!"


# ========================================
# 2. Unauthorized User Access Detection and Response
# ========================================
echo "Starting unauthorized user access detection..."

# Define suspicious user
SUSPICIOUS_USER="hacker"  # Example suspicious user
BLOCK_LIST="/tmp/unauthorized_users.txt"  # File to store suspicious users

# Monitor logs for new user creation or suspicious logins
grep "useradd" $LOG_FILE > $BLOCK_LIST   # Detect new user creations
grep "Failed password" $LOG_FILE | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 > 3' >> $BLOCK_LIST   # Detect failed logins

# Lock or block the suspicious user
while read USER; do
    if [ "$USER" == "$SUSPICIOUS_USER" ]; then
        echo "Blocking unauthorized user $USER..."

        # Lock the user account
        usermod -L $USER

        # Block the user's IP address
        ATTACKING_IP=$(grep "$USER" $LOG_FILE | awk '{print $(NF-3)}')
        iptables -A INPUT -s $ATTACKING_IP -j DROP

        # Send an alert
        echo "Suspicious user $USER detected and account locked."
    fi
done < $BLOCK_LIST

echo "Unauthorized user access detection and response completed!"


# ========================================
# 3. Malicious Process Detection and Response
# ========================================
echo "Starting malicious process detection..."

# Define known malicious processes (example)
MALICIOUS_PROCESSES=("cryptominer" "malware_backdoor" "rootkit")

# Monitor running processes and check for known malicious ones
for PROCESS in "${MALICIOUS_PROCESSES[@]}"; do
    PIDS=$(pgrep -f $PROCESS)
    
    if [ ! -z "$PIDS" ]; then
        echo "Malicious process $PROCESS detected! Terminating the process..."

        # Kill the malicious processes
        for PID in $PIDS; do
            kill -9 $PID
        done

        # Send an alert
        echo "Malicious process $PROCESS terminated"
    fi
done

echo "Malicious process detection and response completed!"


# ========================================
# 4. Suspicious File Modification Detection and Response
# ========================================
echo "Starting file integrity monitoring..."

# Define variables
AIDE_REPORT="/var/log/aide/aide_report.txt"    # AIDE report location
BACKUP_DIR="/backup"                           # Backup directory for restoring files
SUSPICIOUS_FILE="/etc/passwd"                  # Example of a critical file to monitor

# Run AIDE to check file integrity
aide --check > $AIDE_REPORT

# Check if the file modification was detected in the AIDE report
if grep -q "$SUSPICIOUS_FILE" $AIDE_REPORT; then
    echo "Suspicious modification detected on $SUSPICIOUS_FILE!"

    # Take action: restore the file from backup (example)
    cp $BACKUP_DIR/passwd.bak $SUSPICIOUS_FILE

    # Block the IP that caused the modification (example)
    ATTACKING_IP=$(grep "$SUSPICIOUS_FILE" $AIDE_REPORT | awk '{print $3}') # Assuming IP is recorded in the log
    iptables -A INPUT -s $ATTACKING_IP -j DROP

    # Send an alert
    echo "Suspicious file modification detected and response triggered. File restored from backup."
else
    echo "No suspicious file modification detected."
fi

echo "File integrity monitoring and response completed!"


# ========================================
# 5. Brute-Force Attack Detection and Response
# ========================================
echo "Starting brute-force attack detection..."

# Define variables
ATTACK_THRESHOLD=5          # Number of failed login attempts to trigger a response
LOG_FILE="/var/log/auth.log" # Location of the auth log file
BLOCK_LIST="/tmp/blocked_ips.txt"  # File to store blocked IPs

# Monitor auth log for repeated failed login attempts
grep "Failed password" $LOG_FILE | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 > '$ATTACK_THRESHOLD'' > $BLOCK_LIST

# Block each IP address that exceeds the threshold using iptables
while read IP; do
    echo "Blocking IP address $IP for brute-force attempts..."
    iptables -A INPUT -s $IP -j DROP

    # Send an alert about the blocked IP
    echo "Blocked IP address $IP due to multiple failed SSH login attempts"
done < $BLOCK_LIST

echo "Brute-force attack detection and response completed!"

echo "All security monitoring tasks completed successfully!"
