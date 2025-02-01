#!/bin/bash

# LOG ROTATION FOR MONITORING LOGS

echo "Starting log rotation for file and user monitoring logs..."

# Ensure the log files exist
if [ ! -f /var/log/file_changes.log ]; then
    touch /var/log/file_changes.log
    echo "/var/log/file_changes.log created"
fi

if [ ! -f /var/log/user_activity.log ]; then
    touch /var/log/user_activity.log
    echo "/var/log/user_activity.log created"
fi

# 1. Configure logrotate for file change logs
cat <<EOL > /etc/logrotate.d/file_changes
/var/log/file_changes.log {
    daily
    rotate 7
    compress
    notifempty
    create 640 root adm
}
EOL

# 2. Configure logrotate for user activity logs
cat <<EOL > /etc/logrotate.d/user_activity
/var/log/user_activity.log {
    weekly
    rotate 4
    compress
    notifempty
    create 640 root adm
}
EOL

# 3. Force a logrotate to run
echo "Running logrotate..."
logrotate /etc/logrotate.conf

# Check for errors in logrotate execution
if [ $? -eq 0 ]; then
    echo "Logrotate ran successfully!"
else
    echo "Error: Logrotate failed!" >&2
    exit 1
fi

echo "Log rotation setup completed!"

