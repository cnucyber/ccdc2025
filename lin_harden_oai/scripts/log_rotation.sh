#!/bin/bash

# LOG ROTATION FOR MONITORING LOGS

echo "Starting log rotation for file and user monitoring logs..."
LOG_DIR="/var/log"
LOG_FILE_1="file_changes.log"
LOG_FILE_2="user_activity.log"
LOGROTATE_CONF="/etc/logrotate.conf"
LOGROTATE_DIR="/etc/logrotate.d"
LOG_FILE_1_PATH="$LOG_DIR/$LOG_FILE_1"
LOG_FILE_2_PATH="$LOG_DIR/$LOG_FILE_2"

# Function for logging and notifications
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/log_rotation_script.log
}

send_notification() {
    # Placeholder function for sending notifications. Can be customized.
    echo "Notification: $1" | mail -s "Log Rotation Script Notification" admin@example.com
}

# Ensure the log files exist, if not, create them
if [ ! -f $LOG_FILE_1_PATH ]; then
    touch $LOG_FILE_1_PATH
    log_message "$LOG_FILE_1_PATH created"
    echo "$LOG_FILE_1_PATH created"
fi

if [ ! -f $LOG_FILE_2_PATH ]; then
    touch $LOG_FILE_2_PATH
    log_message "$LOG_FILE_2_PATH created"
    echo "$LOG_FILE_2_PATH created"
fi

# 1. Configure logrotate for file change logs
cat <<EOL > $LOGROTATE_DIR/file_changes
$LOG_FILE_1_PATH {
    daily
    rotate 7
    compress
    notifempty
    create 640 root adm
    postrotate
        # Custom script or action after log rotation (e.g., restart a service)
        systemctl reload some-service
    endscript
}
EOL

log_message "Configured logrotate for file_changes.log"

# 2. Configure logrotate for user activity logs
cat <<EOL > $LOGROTATE_DIR/user_activity
$LOG_FILE_2_PATH {
    weekly
    rotate 4
    compress
    notifempty
    create 640 root adm
    postrotate
        # Custom script or action after log rotation (e.g., restart a service)
        systemctl reload another-service
    endscript
}
EOL

log_message "Configured logrotate for user_activity.log"

# Check available disk space before proceeding
DISK_SPACE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_SPACE -ge 90 ]; then
    echo "Warning: Disk space is over 90%. Log rotation will not proceed." >&2
    send_notification "Disk space is over 90%. Log rotation was aborted."
    log_message "Disk space is over 90%. Log rotation aborted."
    exit 1
fi

# 3. Force a logrotate to run
echo "Running logrotate..."
logrotate $LOGROTATE_CONF

# Check for errors in logrotate execution
if [ $? -eq 0 ]; then
    log_message "Logrotate ran successfully!"
    echo "Logrotate ran successfully!"
else
    echo "Error: Logrotate failed!" >&2
    log_message "Error: Logrotate failed!"
    send_notification "Logrotate failed during execution."
    exit 1
fi

# 4. Check logs for any old, unnecessary files and clean them up
echo "Cleaning up old logs..."
find $LOG_DIR -type f -name "*.log" -mtime +30 -exec rm -f {} \;
log_message "Old logs older than 30 days removed"

# 5. Email or notify about completion
send_notification "Log rotation script completed successfully."
log_message "Log rotation script completed successfully."

echo "Log rotation setup completed!"
