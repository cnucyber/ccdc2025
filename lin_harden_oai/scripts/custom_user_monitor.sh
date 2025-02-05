#!/bin/bash

# ==========================================
# INSTALL 'notify-send' IF NOT FOUND
# ==========================================
install_notify_send() {
    if ! command -v notify-send &>/dev/null; then
        echo "'notify-send' not found. Installing it now..."
        sudo apt update
        sudo apt install -y libnotify-bin
    fi
}

# Function to send a terminal notification every time a command is run
send_notification() {
    local command=$1
    notify-send "Command Executed" "$command"
}

# Install 'notify-send' if it's not installed
install_notify_send

# Hook into the shell to trigger the notification every time a command is run
export PROMPT_COMMAND='send_notification "$(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//")"'

echo "Command monitoring is now active. You will receive a notification whenever a command is run."
