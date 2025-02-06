#!/bin/bash

# MASTER INITIALIZATION SCRIPT FOR SYSTEM SECURITY AND MONITORING

# Addes so our logs get added
source ../loggerUnified.sh
create_log

echo "Starting system hardening..."

# ========================================
# 1. Ensure pam_pwquality is installed for password complexity enforcement
# ========================================

echo "Checking and installing pam_pwquality for password complexity enforcement..."

# Check if pam_pwquality is installed (for Debian/Ubuntu-based systems)
if ! dpkg -l | grep -qw libpam-pwquality; then
    echo "pam_pwquality not found, installing..."
    apt update && apt install -y libpam-pwquality || { echo "Failed to install libpam-pwquality"; exit 1; }
else
    echo "pam_pwquality is already installed."
fi

# Configure PAM to enforce password complexity
pam_file="/etc/pam.d/common-password"

if [[ -f "/usr/lib/security/pam_pwquality.so" ]]; then
    if ! grep -q "pam_pwquality.so" "$pam_file"; then
        echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=4" >> "$pam_file"
        echo "Password complexity policy enforced."
    else
        echo "Password complexity policy is already configured."
    fi
else
    echo "Warning: pam_pwquality.so module not found. Skipping password complexity enforcement."
fi


# ========================================
# 2. Ensure the script directory exists
# ========================================
SCRIPT_DIR="./scripts/"

if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Script directory $SCRIPT_DIR does not exist!" >&2
    exit 1
fi

# ========================================
# 3. Run the scripts in the correct order
# ========================================

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

run_script "firewall_config.sh"
run_script "backup.sh"
run_script "custom_system_monitor.sh"
run_script "custom_user_monitor.sh"
run_script "intrusion_detection.sh"
run_script "log_rotation.sh"
run_script "splunk_forwarder_setup.sh"
run_script "system_hardening.sh"

echo "All scripts have been executed successfully!"
