#!/bin/bash

# General Incident Response Workflow

echo "Starting general incident response..."

# Step 1: Brute-force attack detection and response
./response/brute_force_detection.sh

# Step 2: Suspicious file modification detection and response
./response/file_integrity_monitor.sh

# Step 3: Unauthorized user access detection and response
./response/user_access_monitor.sh

# Step 4: Malicious process detection and response
./response/malicious_process_detection.sh

# Step 5: Suspicious network activity detection and response
./response/network_activity_monitor.sh

echo "General incident response completed!"

