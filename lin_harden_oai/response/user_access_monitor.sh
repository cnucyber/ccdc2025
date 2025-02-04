#!/bin/bash

# Unauthorized User Access Detection and Response

echo "Starting unauthorized user access detection..."

# Define variables
LOG_FILE="/var/log/auth.log"          # Location of the auth log file
SUSPICIOUS_USER="hacker"             # Example suspicious user
BLOCK_LIST="/tmp/unauthorized_users.txt" # File to store suspicious users

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

