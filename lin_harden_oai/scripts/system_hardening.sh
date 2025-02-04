#!/bin/bash

# SYSTEM HARDENING

echo "Starting system hardening..."

# ========================================
# 1. Ensure necessary security packages are installed
# ========================================
echo "Installing security-related packages..."
if ! apt-get update && apt-get install -y libpam-pwquality; then
    echo "Failed to install libpam-pwquality. Exiting."
    exit 1
fi

# ========================================
# 2. Disable unused filesystems
# ========================================
echo "Disabling unused filesystems..."
if [ ! -f /etc/modprobe.d/disable.conf ]; then
    touch /etc/modprobe.d/disable.conf
fi

# Disable specific filesystems
for fs in cramfs freevxfs jffs2 hfs hfsplus squashfs; do
    if ! grep -q "^install $fs /bin/true" /etc/modprobe.d/disable.conf; then
        echo "install $fs /bin/true" >> /etc/modprobe.d/disable.conf
    fi
done

# ========================================
# 3. Disable IPv6 if not required
# ========================================
echo "Disabling IPv6..."
sysctl_conf="/etc/sysctl.conf"
if ! grep -q "net.ipv6.conf.all.disable_ipv6 = 1" "$sysctl_conf"; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> "$sysctl_conf"
fi
if ! grep -q "net.ipv6.conf.default.disable_ipv6 = 1" "$sysctl_conf"; then
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> "$sysctl_conf"
fi
sysctl -p

# ========================================
# 4. Disable root SSH login
# ========================================
echo "Disabling root SSH login..."
ssh_config="/etc/ssh/sshd_config"
if [ -f "$ssh_config" ]; then
    if grep -q "^PermitRootLogin" "$ssh_config"; then
        sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' "$ssh_config"
    else
        echo "PermitRootLogin no" >> "$ssh_config"
    fi
    systemctl restart sshd
else
    echo "Error: $ssh_config not found. Skipping root SSH login disable."
fi

# ========================================
# 5. Lock password aging for system accounts (UID < 1000)
# ========================================
echo "Locking password aging for system accounts..."
getent passwd | awk -F: '$3 < 1000 { print $1 }' | while read user; do
    chage -E 0 "$user" || echo "Failed to lock password aging for user $user"
done

# ========================================
# 6. Enforce password complexity
# ========================================
echo "Setting password complexity policy..."
pam_file="/etc/pam.d/common-password"

if [[ -f "/usr/lib/security/pam_pwquality.so" ]]; then
    if ! grep -q "pam_pwquality.so" "$pam_file"; then
        echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=4" >> "$pam_file"
    fi
else
    echo "Warning: pam_pwquality.so module not found. Skipping password complexity enforcement."
fi

# ========================================
# 7. Set default umask
# ========================================
echo "Setting default umask..."
profile_file="/etc/profile"
if ! grep -q "umask 027" "$profile_file"; then
    echo "umask 027" >> "$profile_file"
fi

# ========================================
# 8. Disable accounts with weak passwords
# ========================================
echo "Checking for weak passwords and locking accounts..."

MIN_PASSWORD_LENGTH=12

while IFS=: read -r user _ uid _; do
    if [ "$uid" -ge 1000 ]; then
        shadow_entry=$(grep "^$user:" /etc/shadow)
        if [[ -n "$shadow_entry" ]]; then
            password_hash=$(echo "$shadow_entry" | cut -d: -f2)
            
            # Skip users with locked accounts
            if [[ "$password_hash" == "!" || "$password_hash" == "*" ]]; then
                continue
            fi

            # Check password length
            password_length=$(echo "$password_hash" | wc -m)
            if [ "$password_length" -lt "$MIN_PASSWORD_LENGTH" ]; then
                passwd -l "$user"
                echo "Account $user disabled due to weak password."
            fi
        fi
    fi
done < /etc/passwd

# ========================================
# 9. Apply changes and finalize hardening
# ========================================
echo "System hardening completed successfully!"
