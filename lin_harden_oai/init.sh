#!/bin/bash

# MASTER INITIALIZATION SCRIPT FOR SYSTEM SECURITY AND MONITORING

# Define the directory where the scripts are located
SCRIPT_DIR="./scripts/"

# Function to run a script and check for errors
run_script() {
    local SCRIPT_NAME=$1
    local SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

    if [ -f "$SCRIPT_PATH" ]; then
        echo "Running $SCRIPT_NAME..."
        bash "$SCRIPT_PATH"
        if [ $? -eq 0 ]; then
            echo "$SCRIPT_NAME completed successfully."
        else
            echo "Error: $SCRIPT_NAME failed!" >&2
            exit 1
        fi
    else
        echo "Error: $SCRIPT_NAME not found in $SCRIPT_DIR!" >&2
        exit 1
    fi
}

# Ensure the script directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Script directory $SCRIPT_DIR does not exist!" >&2
    exit 1
fi

# Run the scripts in the correct order
run_script "firewall_config.sh"
run_script "backup.sh"
run_script "custom_system_monitor.sh"
run_script "custom_user_monitor.sh"
run_script "intrusion_detection.sh"
run_script "log_rotation.sh"
run_script "splunk_forwarder_setup.sh"
run_script "system_hardening.sh"

echo "All scripts have been executed successfully!"
