#!/bin/bash

# SYSTEM HARDENING (Debian, Ubuntu, RHEL, CentOS, Fedora Compatible)

echo "Starting system hardening..."

# Detect Package Manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    INSTALL_CMD="apt-get install -y"
    UPDATE_CMD="apt-get update"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="dnf install -y"
    UPDATE_CMD="dnf check-update"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    INSTALL_CMD="yum install -y"
    UPDATE_CMD="yum check-update"
else
    echo "Unsupported package manager. Exiting..."
    exit 1
fi

# ========================================
# 1. Ensure necessary security packages are installed
# ========================================
echo "Installing security-related packages..."
$UPDATE_CMD
$INSTALL_CMD libpam-pwquality auditd

# ========================================
# 2. Disable unused filesystems
# ========================================
echo "Disabling unused filesystems..."
DISABLE_CONF="/etc/modprobe.d/disable.conf"
[ ! -f "$DISABLE_CONF" ] && touch "$DISABLE_CONF"

for fs in cramfs freevxfs jffs2 hfs hfsplus squashfs; do
    if ! grep -q "^install $fs /bin/true" "$DISABLE_CONF"; then
        echo "install $fs /bin/true" >> "$DISABLE_CONF"
    fi
done

# ========================================
# 3. Disable IPv6 (Handles both Debian-based & RHEL-based)
# ========================================
echo "Disabling IPv6..."
SYSCTL_CONF="/etc/sysctl.conf"
cat <<EOL >> "$SYSCTL_CONF"
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOL
sysctl -p

# RHEL-based systems also need /etc/sysconfig/network update
if [[ -f "/etc/sysconfig/network" ]]; then
    echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
    echo "IPV6INIT=no" >> /etc/sysconfig/network
fi

# ========================================
# 4. Disable root SSH login (Debian & RHEL variants)
# ========================================
echo "Disabling root SSH login..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ -f "$SSH_CONFIG" ]; then
    sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' "$SSH_CONFIG"
    echo "PermitRootLogin no" >> "$SSH_CONFIG"
    
    # Restart SSH service correctly based on system
    if command -v systemctl &> /dev/null; then
        systemctl restart sshd 2>/dev/null || systemctl restart ssh
    else
        service sshd restart 2>/dev/null || service ssh restart
    fi
fi

# ========================================
# 5. Lock password aging for system accounts (UID < 1000)
# ========================================
echo "Locking password aging for system accounts..."
awk -F: '$3 < 1000 {print $1}' /etc/passwd | while read -r user; do
    chage -E 0 "$user" || echo "Failed to lock password aging for user $user"
done

# ========================================
# 6. Enforce password complexity (Debian vs RHEL)
# ========================================
echo "Setting password complexity policy..."
if [ -f "/etc/security/pwquality.conf" ]; then
    cat <<EOL > /etc/security/pwquality.conf
minlen = 12
retry = 3
difok = 4
ucredit = -1
lcredit = -1
dcredit = -1
ocredit = -1
EOL
elif [ -f "/etc/pam.d/system-auth" ]; then
    echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=4" >> /etc/pam.d/system-auth
else
    echo "Warning: No valid password policy file found."
fi

# ========================================
# 7. Set default umask
# ========================================
echo "Setting default umask..."
PROFILE_FILE="/etc/profile"
if ! grep -q "umask 027" "$PROFILE_FILE"; then
    echo "umask 027" >> "$PROFILE_FILE"
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
            
            # Skip locked accounts
            if [[ "$password_hash" == "!" || "$password_hash" == "*" ]]; then
                continue
            fi

            # Lock accounts with empty passwords
            if [[ -z "$password_hash" || "$password_hash" == "!!" ]]; then
                passwd -l "$user"
                echo "Account $user disabled due to weak password."
            fi
        fi
    fi
done < /etc/passwd

# ========================================
# 9. Ensure auditd is running
# ========================================
echo "Ensuring auditd is running..."
if command -v systemctl &> /dev/null; then
    systemctl enable --now auditd 2>/dev/null || echo "auditd failed to start."
else
    service auditd start || echo "auditd service start failed."
fi

# ========================================
# 10. Apply changes and finalize hardening
# ========================================
echo "System hardening completed successfully!"
