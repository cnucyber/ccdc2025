#!/bin/bash

# SPLUNK UNIVERSAL FORWARDER SETUP

echo "Starting Splunk Universal Forwarder setup..."

# Ensure required tools are installed (wget, tar, unzip)
if ! command -v wget &> /dev/null || ! command -v tar &> /dev/null; then
    echo "wget or tar is not installed. Installing..."
    apt-get update && apt-get install wget tar -y || { echo "Failed to install required tools"; exit 1; }
fi

# 1. Download the Splunk Universal Forwarder (replace with actual download link)
echo "Downloading Splunk Universal Forwarder..."
wget -O /tmp/splunkforwarder-8.x.x-linux-x86_64.tgz "https://download.splunk.com/releases/8.x.x/universalforwarder/splunkforwarder-8.x.x-linux-x86_64.tgz"

# 2. Verify the file type (to ensure it is .tgz)
file_type=$(file -b /tmp/splunkforwarder-8.x.x-linux-x86_64.tgz)

if [[ $file_type == *"gzip compressed data"* ]]; then
    echo "Extracting Splunk Universal Forwarder (gzip format)..."
    tar -xzvf /tmp/splunkforwarder-8.x.x-linux-x86_64.tgz -C /opt/
else
    echo "The downloaded file is not in the expected gzip format. Exiting..."
    exit 1
fi

# 3. Start the Splunk Universal Forwarder
echo "Starting Splunk Universal Forwarder..."
cd /opt/splunkforwarder/bin
./splunk start --accept-license

# 4. Enable Splunk to start on boot
echo "Enabling Splunk Universal Forwarder to start on boot..."
./splunk enable boot-start

# 5. Prompt the user for the Splunk server IP
read -p "Enter the IP address of the Splunk server: " splunk_server_ip

# 6. Configure the Forwarder to Send Logs
echo "Configuring Splunk Forwarder inputs..."

cat <<EOL > /opt/splunkforwarder/etc/system/local/inputs.conf
[monitor:///var/log/syslog]
disabled = false
index = os_logs

[monitor:///var/log/auth.log]
disabled = false
index = auth_logs

[monitor:///var/log/custom_logs/]
disabled = false
index = custom_logs
EOL

# 7. Define the destination Splunk server with the user-provided IP
echo "Configuring Splunk Forwarder outputs..."
cat <<EOL > /opt/splunkforwarder/etc/system/local/outputs.conf
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = $splunk_server_ip:9997
EOL

# 8. Restart the Splunk Universal Forwarder to apply changes
echo "Restarting Splunk Universal Forwarder..."
/opt/splunkforwarder/bin/splunk restart

echo "Splunk Universal Forwarder setup completed!"
