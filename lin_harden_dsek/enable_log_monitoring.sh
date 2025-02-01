#!/bin/bash

# Install auditd if not already installed
if ! command -v auditd &> /dev/null; then
    if command -v apt &> /dev/null; then
        sudo apt install auditd -y
    elif command -v yum &> /dev/null; then
        sudo yum install audit -y
    elif command -v dnf &> /dev/null; then
        sudo dnf install audit -y
    elif command -v zypper &> /dev/null; then
        sudo zypper install audit -y
    else
        echo "Unsupported package manager. Skipping auditd installation."
    fi
fi

# Configure auditd rules
if command -v auditd &> /dev/null; then
    sudo tee /etc/audit/rules.d/hardening.rules <<EOF
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /var/log/ -p wa -k logs
-w /etc/ssh/sshd_config -p wa -k sshd
EOF
    sudo systemctl restart auditd
fi

# Install and configure rsyslog if not already installed
if ! command -v rsyslogd &> /dev/null; then
    if command -v apt &> /dev/null; then
        sudo apt install rsyslog -y
    elif command -v yum &> /dev/null; then
        sudo yum install rsyslog -y
    elif command -v dnf &> /dev/null; then
        sudo dnf install rsyslog -y
    elif command -v zypper &> /dev/null; then
        sudo zypper install rsyslog -y
    else
        echo "Unsupported package manager. Skipping rsyslog installation."
    fi
fi

if command -v rsyslogd &> /dev/null; then
    sudo systemctl enable rsyslog
    sudo systemctl start rsyslog
fi

echo "Log monitoring enabled!"
