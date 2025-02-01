#!/bin/bash

# SYSTEM HARDENING

echo "Starting system hardening..."

# 1. Disable unused filesystems
echo "Disabling unused filesystems..."
if [ ! -f /etc/modprobe.d/disable.conf ]; then
    echo "Creating /etc/modprobe.d/disable.conf..."
    touch /etc/modprobe.d/disable.conf
fi

# Disable specific filesystems by installing them as "true" (effectively disabling them)
for fs in cramfs freevxfs jffs2 hfs hfsplus squashfs; do
    echo "install $fs /bin/true" >> /etc/modprobe.d/disable.conf
done

# 2. Disable IPv6 if not required
echo "Disabling IPv6..."
if ! grep -q "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf; then
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
fi
sysctl -p

# 3. Disable root SSH login
echo "Disabling root SSH login..."
if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
else
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi
systemctl restart sshd

# 4. Lock password aging for system accounts (UID < 1000)
echo "Locking password aging for system accounts..."
for user in $(cut -f1 -d: /etc/passwd); do
    user_uid=$(grep "^$user:" /etc/passwd | cut -d: -f3)
    if [ "$user_uid" -lt 1000 ]; then
        chage -E 0 $user
    fi
done

# 5. Enforce password complexity
echo "Setting password complexity..."
if ! grep -q "pam_pwquality.so" /etc/pam.d/common-password; then
    echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=4" >> /etc/pam.d/common-password
fi

# 6. Set umask to restrict permissions
echo "Setting default umask..."
if ! grep -q "umask 027" /etc/profile; then
    echo "umask 027" >> /etc/profile
fi

# 7. Disable accounts with weak passwords
echo "Disabling accounts with weak passwords..."

# Set minimum password length to 12 characters
MIN_PASSWORD_LENGTH=12

# Loop through all user accounts and check their password length
for user in $(cut -f1 -d: /etc/passwd); do
    # Skip system users with UID < 1000
    user_uid=$(grep "^$user:" /etc/passwd | cut -d: -f3)
    if [ "$user_uid" -lt 1000 ]; then
        continue
    fi
    
    # Check password status using the "passwd -S" command
    password_status=$(passwd -S $user | awk '{print $2}')
    
    if [ "$password_status" != "L" ]; then
        # Check password strength by looking for length
        password_length=$(echo "$user" | awk '{print length($1)}')
        
        if [ "$password_length" -lt "$MIN_PASSWORD_LENGTH" ]; then
            # Lock the account if the password is weak
            passwd -l $user
            echo "Account $user disabled due to weak password."
        fi
    fi
done

# 8. Apply changes and finalize hardening
echo "System hardening completed!"

