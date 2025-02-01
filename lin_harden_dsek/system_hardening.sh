#!/bin/bash

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
else
    echo "Unsupported package manager. Exiting."
    exit 1
fi

# Update and upgrade the system
sudo $PKG_MANAGER update -y
sudo $PKG_MANAGER upgrade -y

# Disable root login (if SSH is installed)
if [ -f /etc/ssh/sshd_config ]; then
    sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
fi

# Enable automatic security updates
if [ "$PKG_MANAGER" = "apt" ]; then
    sudo $PKG_MANAGER install unattended-upgrades -y
    sudo dpkg-reconfigure --priority=low unattended-upgrades
elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
    sudo $PKG_MANAGER install yum-cron -y
    sudo systemctl enable yum-cron
    sudo systemctl start yum-cron
fi

# Set up a firewall (UFW or firewalld)
if command -v ufw &> /dev/null; then
    sudo ufw allow ssh
    sudo ufw enable
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload
fi

# Set stricter file permissions
sudo chmod 600 /etc/shadow
sudo chmod 644 /etc/passwd
sudo chmod 640 /etc/group

echo "System hardening complete!"
