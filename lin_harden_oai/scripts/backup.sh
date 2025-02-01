#!/bin/bash

# BACKUP CONFIGURATION

echo "Setting up automated backups..."

# Define log file for backup process
BACKUP_LOG="/var/log/backup.log"

# Ensure the backup directory exists
mkdir -p /backup

# Set permissions for the backup folder
chmod 700 /backup
chmod 600 /backup/*

# Function to log and check for errors
log_message() {
    local MESSAGE=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" >> $BACKUP_LOG
}

# Function to handle backup creation
create_backup() {
    local BACKUP_FILE="/backup/$(date +\%F_\%H-\%M).tar.gz"
    local SOURCE_DIR="/important_data/"

    # Create the backup and log the result
    tar -czf $BACKUP_FILE $SOURCE_DIR 2>>$BACKUP_LOG
    if [ $? -eq 0 ]; then
        log_message "Backup successful: $BACKUP_FILE"
    else
        log_message "ERROR: Backup failed for $SOURCE_DIR"
        return 1
    fi
}

# Set up cron job for backups every 30 minutes
echo "*/30 * * * * root /bin/bash /path/to/backup_script.sh >> /dev/null 2>&1" > /etc/cron.d/backup

# Perform the backup
create_backup

# Perform backup rotation: keep the last 14 backups (every 30 minutes means 14 backups in 1 day)
find /backup -type f -name "*.tar.gz" -mtime +1 -exec rm -f {} \; 2>>$BACKUP_LOG

# Log completion
log_message "Backup and disaster recovery setup completed!"

