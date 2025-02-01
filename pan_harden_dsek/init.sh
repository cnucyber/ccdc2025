#!/bin/bash
# Palo Alto Firewall Hardening Script
# This script configures best security practices for a Palo Alto firewall via CLI

set -e

logfile="/var/log/palo_alto_hardening.log"
echo "Starting Palo Alto Firewall hardening..." | tee -a "$logfile"

# Ensure we are in configure mode
echo "Entering configuration mode..." | tee -a "$logfile"
cli_command="configure"
echo "$cli_command" | cli

# 1. Set Admin Account Security
echo "Setting strong admin password policy..." | tee -a "$logfile"
cli_command="set mgt-config users admin password"
echo "$cli_command" | cli

# 2. Disable Unused Services
echo "Disabling unnecessary services..." | tee -a "$logfile"
cli_command=" set deviceconfig setting management ssh no"
echo "$cli_command" | cli

# 3. Restrict Management Access
echo "Restricting management access..." | tee -a "$logfile"
cli_command="set deviceconfig system permitted-ip <ALLOWED_IPS>"
echo "$cli_command" | cli

# 4. Enable Logging for All Rules
echo "Enabling logging for all security rules..." | tee -a "$logfile"
cli_command="set rulebase security rules all log-start yes; set rulebase security rules all log-end yes"
echo "$cli_command" | cli

# 5. Set Minimum TLS Version
echo "Enforcing strong TLS policies..." | tee -a "$logfile"
cli_command="set deviceconfig setting ssl tlsv1.2 enable yes"
echo "$cli_command" | cli

# 6. Enable Threat Prevention
echo "Enabling threat prevention features..." | tee -a "$logfile"
cli_command="set rulebase security rules all profile-setting profiles antivirus default; set rulebase security rules all profile-setting profiles vulnerability default; set rulebase security rules all profile-setting profiles spyware default; set rulebase security rules all profile-setting profiles url-filtering default"
echo "$cli_command" | cli

# 7. Detect and Configure Interfaces for Zones
echo "Detecting and configuring interfaces..." | tee -a "$logfile"
interfaces=$(cli -c "show interface all" | awk '/ethernet/{print $1}')
zone_names=("external" "public" "user" "internal")
index=0
for interface in $interfaces; do
    if [ $index -lt ${#zone_names[@]} ]; then
        zone=${zone_names[$index]}
        echo "Assigning interface $interface to zone $zone..." | tee -a "$logfile"
        cli_command="set network interface $interface zone $zone"
        echo "$cli_command" | cli
        index=$((index+1))
    fi
done

# 8. Apply Zone Protection
echo "Applying zone protection profiles..." | tee -a "$logfile"
cli_command="set network zone untrust network layer3 enable-zone-protection yes; set network zone trust network layer3 enable-zone-protection yes"
echo "$cli_command" | cli

# 9. Block Unauthorized Applications
echo "Blocking unauthorized applications..." | tee -a "$logfile"
cli_command="set rulebase security rules block-applications action deny; set rulebase security rules block-applications application any"
echo "$cli_command" | cli

# 10. Enable DNS Security
echo "Enabling DNS security..." | tee -a "$logfile"
cli_command="set deviceconfig setting dns-security enable yes"
echo "$cli_command" | cli

# 11. Configure SSL Decryption with Self-Signed Certificate
echo "Configuring SSL decryption..." | tee -a "$logfile"
cli_command="set shared certificate ssl-decrypt-cert common-name SSL_Decryption_Cert generate-key yes"
echo "$cli_command" | cli
cli_command="set shared ssl-decryption ssl-inbound-inspection enable yes"
echo "$cli_command" | cli
cli_command="set shared ssl-decryption ssl-forward-proxy enable yes"
echo "$cli_command" | cli

# 12. Save Configuration
echo "Saving final configuration..." | tee -a "$logfile"
cli_command="commit"
echo "$cli_command" | cli

echo "Palo Alto Firewall hardening complete!" | tee -a "$logfile"
exit 0

