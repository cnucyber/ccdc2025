#!/bin/bash

# OSSEC INSTALLATION SCRIPT (Automated with `expect`)

echo "Starting OSSEC automated installation..."

# Install dependencies
apt update && apt install -y curl unzip build-essential expect

# Download OSSEC installer
curl -L -o /tmp/ossec.tar.gz https://github.com/ossec/ossec-hids/archive/refs/tags/3.7.0.tar.gz

# Extract the installer
tar -xvzf /tmp/ossec.tar.gz -C /tmp/

# Change directory to OSSEC source
cd /tmp/ossec-hids-3.7.0/

# Create expect script for OSSEC installation
cat << 'EOF' > /tmp/ossec_install.expect
#!/usr/bin/expect -f

spawn ./install.sh

expect "What kind of installation do you want?"
send "server\r"

expect "Where do you want to install it?"
send "/var/ossec\r"

expect "Do you want e-mail notification?"
send "n\r"

expect "Do you want to run the integrity check daemon?"
send "y\r"

expect "Do you want t
