#!/bin/bash

# Suspicious Network Activity Detection and Response

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
    echo "Blocked IP address $IP for suspicious network activity." | mail -s "Suspicious Network Activity Detected" admin@example.com
done < $BLOCK_LIST

echo "Suspicious network activity detection and response completed!"

