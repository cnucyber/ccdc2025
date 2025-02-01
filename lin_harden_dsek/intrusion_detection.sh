#!/bin/bash

# Install AIDE if not already installed
if ! command -v aide &> /dev/null; then
    if command -v apt &> /dev/null; then
        sudo apt install aide -y
    elif command -v yum &> /dev/null; then
        sudo yum install aide -y
    elif command -v dnf &> /dev/null; then
        sudo dnf install aide -y
    elif command -v zypper &> /dev/null; then
        sudo zypper install aide -y
    else
        echo "Unsupported package manager. Skipping AIDE installation."
        exit 1
    fi
fi

# Initialize AIDE database
sudo aideinit --yes

# Schedule daily AIDE checks
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
sudo echo "0 5 * * * /usr/bin/aide --check" | sudo tee /etc/cron.d/aide-check

echo "Intrusion detection with AIDE configured!"
