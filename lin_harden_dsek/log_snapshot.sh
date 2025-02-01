#!/bin/bash

# Create a directory for log snapshots
sudo mkdir -p /var/log/snapshots

# Create a script to take snapshots
sudo tee /usr/local/bin/log_snapshot.sh <<EOF
#!/bin/bash
TIMESTAMP=\$(date +"%Y%m%d%H%M%S")
rsync -a /var/log/ /var/log/snapshots/logs-\$TIMESTAMP
find /var/log/snapshots/ -type d -mtime +7 -exec rm -rf {} \;
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/log_snapshot.sh

# Schedule daily snapshots
sudo echo "0 0 * * * /usr/local/bin/log_snapshot.sh" | sudo tee /etc/cron.d/log_snapshot

echo "Snapshot system for critical logs configured!"
