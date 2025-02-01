#!/bin/bash

# Install psad if not already installed
if ! command -v psad &> /dev/null; then
    if command -v apt &> /dev/null; then
        sudo apt install psad -y
    elif command -v yum &> /dev/null; then
        sudo yum install psad -y
    elif command -v dnf &> /dev/null; then
        sudo dnf install psad -y
    elif command -v zypper &> /dev/null; then
        sudo zypper install psad -y
    else
        echo "Unsupported package manager. Skipping psad installation."
        exit 1
    fi
fi

# Configure psad
if command -v psad &> /dev/null; then
    sudo sed -i 's/ENABLE_AUTO_IDS      N;/ENABLE_AUTO_IDS      Y;/' /etc/psad/psad.conf
    sudo systemctl enable psad
    sudo systemctl start psad
fi

# Custom script to monitor suspicious processes
sudo tee /usr/local/bin/monitor_processes.sh <<EOF
#!/bin/bash
while true; do
    ps aux | grep -E "(cryptominer|backdoor|malware)" | grep -v grep
    if [ \$? -eq 0 ]; then
        echo "Suspicious process detected!" | mail -s "Alert" admin@example.com
    fi
    sleep 60
done
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/monitor_processes.sh

# Add to crontab
sudo echo "@reboot /usr/local/bin/monitor_processes.sh" | sudo tee /etc/cron.d/monitor_processes

echo "Suspicious process monitoring enabled!"
