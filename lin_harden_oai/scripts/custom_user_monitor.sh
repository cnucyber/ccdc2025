#!/bin/bash

# Check if the necessary tool 'notify-send' is available
if ! command -v notify-send &>/dev/null; then
    echo "notify-send not found, please install it to receive notifications."
    exit 1
fi

# Function to send a terminal notification every time a command is run
send_notification() {
    local command=$1
    notify-send "Command Executed" "$command"
}

# Hook into the shell to trigger the notification every time a command is run
export PROMPT_COMMAND='send_notification "$(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//")"'

echo "Command monitoring is now active. You will receive a notification whenever a command is run."
