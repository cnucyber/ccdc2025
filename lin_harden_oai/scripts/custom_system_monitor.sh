#!/bin/bash

# CUSTOM SYSTEM MONITORING SCRIPT

# Settings
MONITOR_DIRS="/etc /bin /usr/bin /var /root"
LOG_FILE="/var/log/file_changes.log"

# Ensure inotifywait is installed
if ! command -v inotifywait &> /dev/null; then
    echo "inotifywait is not installed. Installing inotify-tools..."
    apt-get update && apt-get install inotify-tools -y || { echo "Failed to install inotify-tools"; exit 1; }
fi

# Ensure the log directory exists and is writable
LOG_DIR=$(dirname "$LOG_FILE")
if [ ! -d "$LOG_DIR" ]; then
    echo "Log directory $LOG_DIR does not exist. Creating it..."
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
fi

# Function to monitor file changes using inotifywait
monitor_changes() {
    echo "Starting file monitoring on directories: $MONITOR_DIRS"

    # Monitor changes in critical directories
    inotifywait -m -r -e modify,create,delete,move $MONITOR_DIRS |
    while read dir action file; do
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$timestamp - $action detected on $dir$file" >> $LOG_FILE
    done
}

# Run the monitoring function in the background (as a daemon)
monitor_changes &

# Optionally, notify user that monitoring is running
echo "Monitoring file changes in the background. Logs will be written to $LOG_FILE"

