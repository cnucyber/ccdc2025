#!/bin/bash

# SPLUNK UNIVERSAL FORWARDER SETUP

# Needed to grab our logs
src_dir=$(dirname "$(realpath "$0")")
host=$(hostname)

echo "Starting Splunk Universal Forwarder setup..."

# Ensure required tools are installed (wget, tar, unzip)
if ! command -v wget &> /dev/null || ! command -v tar &> /dev/null || ! command -v unzip &> /dev/null; then
    echo "wget, tar, or unzip is not installed. Installing..."
    apt-get update && apt-get install wget tar unzip -y || { echo "Failed to install required tools"; exit 1; }
fi

# 1. Detect the Operating System and Architecture
OS=$(uname -s)
ARCH=$(uname -m)

# Define the download URL based on OS and architecture
if [[ "$OS" == "Linux" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.2/linux/splunkforwarder-9.1.2-b6b9c8185839-Linux-x86_64.tgz"
    elif [[ "$ARCH" == "aarch64" ]]; then
        DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.2/linux/splunkforwarder-9.1.2-b6b9c8185839-Linux-armv8.tgz"
    elif [[ "$ARCH" == "ppc64le" ]]; then
        DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.2/linux/splunkforwarder-9.1.2-b6b9c8185839-Linux-ppc64le.tgz"
    elif [[ "$ARCH" == "s390x" ]]; then
        DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.2/linux/splunkforwarder-9.1.2-b6b9c8185839-Linux-s390x.tgz"
    else
        echo "Unsupported Linux architecture $ARCH. Exiting..."
        exit 1
    fi
elif [[ "$OS" == "Darwin" ]]; then
    DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.2/osx/splunkforwarder-9.1.2-b6b9c8185839-darwin-universal2.tgz"
elif [[ "$OS" == "FreeBSD" ]]; then
    DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.2/freebsd/splunkforwarder-9.1.2-b6b9c8185839-FreeBSD11-amd64.tgz"
else
    echo "Unsupported operating system $OS. Exiting..."
    exit 1
fi

# 2. Download the Splunk Universal Forwarder
echo "Downloading Splunk Universal Forwarder from $DOWNLOAD_URL..."
wget --header="User-Agent: Mozilla/5.0" -O /tmp/splunkforwarder.tgz "$DOWNLOAD_URL"

# Check if download was successful
if [[ $? -ne 0 ]]; then
    echo "Failed to download Splunk Universal Forwarder. Exiting..."
    exit 1
fi

# 3. Extract the downloaded file
echo "Extracting Splunk Universal Forwarder..."
tar -xzvf /tmp/splunkforwarder.tgz -C /opt/ || { echo "Failed to extract Splunk Universal Forwarder. Exiting..."; exit 1; }

# 4. Start the Splunk Universal Forwarder
echo "Starting Splunk Universal Forwarder..."
cd /opt/splunkforwarder/bin
./splunk start --accept-license

# 5. Enable Splunk to start on boot
echo "Enabling Splunk Universal Forwarder to start on boot..."
./splunk enable boot-start

# 6. Prompt the user for the Splunk server IP
read -p "Enter the IP address of the Splunk server: " splunk_server_ip

# 7. Configure the Forwarder to Send Logs
echo "Configuring Splunk Forwarder inputs..."
cat <<EOL > /opt/splunkforwarder/etc/system/local/inputs.conf

[monitor:///var/log/auth.log]
disabled = false
index = security
sourcetype = linux_secure

[monitor:///var/log/syslog]
index = system
sourcetype = syslog

[monitor:///var/log/kern.log]
index = system
sourcetype = kernel

[monitor:///var/log/audit/audit.log]
index = security
sourcetype = auditd

[monitor:///var/log/nginx/access.log]
index = web
sourcetype = nginx_access

[monitor:///var/log/nginx/error.log]
index = web
sourcetype = nginx_error

[monitor:///var/log/iptables.log]
index = firewall
sourcetype = iptables

[monitor:///var/log/cron]
index = system
sourcetype = cron

[monitor://${src_dir}/${host}.csv]
disabled = false
index = csv_logs
sourcetype = csv_data
EOL

# 8. Define props.conf for CSV field extraction
echo "Configuring Splunk props for CSV parsing..."
cat <<EOL > /opt/splunkforwarder/etc/system/local/props.conf
[csv_data]
INDEXED_EXTRACTIONS = csv
FIELD_DELIMITER = ,
HEADER_FIELD_LINE_NUMBER = 1
TIMESTAMP_FIELDS = timestamp
TIME_FORMAT = %Y-%m-%d %H:%M:%S
SHOULD_LINEMERGE = false
EOL

# 9. Define the destination Splunk server with the user-provided IP
echo "Configuring Splunk Forwarder outputs..."
cat <<EOL > /opt/splunkforwarder/etc/system/local/outputs.conf
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = $splunk_server_ip:9997
EOL

# 10. Restart the Splunk Universal Forwarder to apply changes
echo "Restarting Splunk Universal Forwarder..."
/opt/splunkforwarder/bin/splunk restart

echo "Splunk Universal Forwarder setup completed!"
