#!/bin/bash

# Brute-Force Attack Detection and Response

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

