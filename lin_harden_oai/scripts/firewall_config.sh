#!/bin/bash

# FIREWALL CONFIGURATION

echo "Configuring firewall..."

# Flush existing rules
iptables -F
iptables -X

# Set default policy to DROP all incoming traffic (except for allowed ones)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow traffic on the loopback interface
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections (return traffic for established sessions)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow incoming SSH (port 22), HTTP (port 80), and HTTPS (port 443)
# If you're restricting SSH to specific IPs, modify the following line accordingly
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Block incoming ICMP ping requests (consider changing to REJECT instead of DROP for logging)
iptables -A INPUT -p icmp --icmp-type echo-request -j REJECT

# DoS Protection - Rate Limiting
# Limit incoming connections to 10/s on HTTP and HTTPS ports to prevent DoS attacks
iptables -A INPUT -p tcp --dport 80 -m limit --limit 10/s -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 10/s -j ACCEPT

# Prevent TCP SYN Flooding
# Drop packets with the SYN flag set (part of the protection against TCP SYN Flood attacks)
iptables -A INPUT -p tcp --syn -j DROP

# Reject invalid packets
iptables -A INPUT -m state --state INVALID -j DROP

# Log suspicious incoming connections (you can adjust this rule to log other types of traffic)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "Suspicious connection: "

# Save firewall rules (for persistence across reboots)
# On Debian/Ubuntu, use iptables-persistent or netfilter-persistent
echo "Saving firewall rules..."
iptables-save > /etc/iptables/rules.v4

# On CentOS/RedHat, you can use the following:
# service iptables save

echo "Firewall configuration completed!"

