#!/bin/bash

# FIREWALL CONFIGURATION - Enhanced Security with Threat Detection

echo "Configuring advanced firewall with threat detection..."

# Ensure iptables is installed
if ! command -v iptables &> /dev/null; then
    echo "iptables is not installed. Installing..."
    apt-get update && apt-get install -y iptables iptables-persistent || { echo "Failed to install iptables"; exit 1; }
fi

# Flush existing rules to prevent conflicts
iptables -F
iptables -X
iptables -Z  # Zero packet counters

# Set default policy to DROP all incoming and forwarding traffic
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow return traffic for established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow Safe Services (Modify as needed)
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT  # SSH
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT  # HTTP
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT # HTTPS

# Malicious Traffic Protection

# Block ICMP ping (consider using REJECT instead of DROP to log attempts)
iptables -A INPUT -p icmp --icmp-type echo-request -j REJECT

# Block NULL packets (often used in stealth scans)
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Block XMAS packets (used in stealth scans)
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Block fragmented packets (often used in evasion techniques)
iptables -A INPUT -f -j DROP

# Block bad TCP flag combinations (potential intrusion attempts)
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP

# Denial-of-Service (DoS) Protection

# Limit incoming connections per second on SSH to prevent brute force
iptables -A INPUT -p tcp --dport 22 -m limit --limit 5/min --limit-burst 10 -j ACCEPT

# Limit HTTP/HTTPS connections to prevent simple DoS attacks
iptables -A INPUT -p tcp --dport 80 -m limit --limit 20/sec --limit-burst 50 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 20/sec --limit-burst 50 -j ACCEPT

# Block excessive connections from a single IP (Aggressive DoS protection)
iptables -A INPUT -p tcp --syn -m recent --name synflood --set
iptables -A INPUT -p tcp --syn -m recent --name synflood --update --seconds 60 --hitcount 30 -j DROP

# Logging and Intrusion Detection

# Log and Drop Packets from Bogus TCP Flags (Intrusion Attempts)
iptables -A INPUT -m state --state INVALID -j LOG --log-prefix "INVALID_PKT: "
iptables -A INPUT -m state --state INVALID -j DROP

# Log and Drop Excessive ICMP Requests (Ping Flood Protection)
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/sec --limit-burst 3 -j LOG --log-prefix "ICMP_FLOOD: "
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# Log all dropped packets for forensic analysis
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "FIREWALL_DROP: "

# IP Banning for Detected Attacks (Adaptive Response)

# Automatically block IPs that hit more than 10 failed SSH attempts in 1 minute
iptables -A INPUT -p tcp --dport 22 -m recent --set --name SSH_ATTACKERS --rsource
iptables -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 10 --name SSH_ATTACKERS --rsource -j DROP

# Persisting Firewall Rules

# Ensure the iptables rules directory exists
if [ ! -d "/etc/iptables" ]; then
    mkdir -p /etc/iptables
fi

# Save the firewall rules for persistence across reboots
iptables-save > /etc/iptables/rules.v4
netfilter-persistent save

echo "Advanced firewall configuration completed with built-in threat protection!"
