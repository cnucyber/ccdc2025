#!/bin/bash

# Suspicious File Modification Detection and Response

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
    echo "Suspicious file modification detected and response triggered. File restored from backup." | mail -s "Suspicious File Modification" admin@example.com
else
    echo "No suspicious file modification detected."
fi

echo "File integrity monitoring and response completed!"

