#!/bin/bash

# Palo Alto Network Automation and Hardening Script
# This script automates various tasks on a Palo Alto firewall via CLI with hardening features.
source ../loggerUnified.sh
set -e

logfile="/var/log/palo_alto_automation_hardening.log"

# Log starting time
echo "Starting Palo Alto Network Automation and Hardening..." | tee -a "$logfile"
add_log_info "us" "Starting Palo Alto Network Automation and Hardening..."

# Prompt user for admin password and confirm it
while true; do
    read -sp "Enter the admin password (strong password recommended): " admin_password
    echo
    read -sp "Confirm the admin password: " admin_password_confirm
    echo
    if [ "$admin_password" == "$admin_password_confirm" ]; then
        echo "Passwords match. Proceeding..." | tee -a "$logfile"
        add_log_success "us" "Admin Password confermed"
        break
    else
        echo "Passwords do not match. Please try again." | tee -a "$logfile"
        add_log_warn "us" "Incorrect password entered"
    fi
done

# Prompt user for allowed IPs for management access
read -p "Enter allowed management IPs (comma-separated, e.g., 192.168.1.100,192.168.1.101): " allowed_ips

# Ensure we are in configure mode
enter_config_mode() {
    echo "Entering configuration mode..." | tee -a "$logfile"
    cli_command="configure"
    echo "$cli_command" | cli
    add_log_info "us" "Entering configuration mode..."
}

# 1. Set Admin Account Security
set_admin_password_policy() {
    echo "Setting strong admin password policy..." | tee -a "$logfile"
    cli_command="set mgt-config users admin password $admin_password"
    echo "$cli_command" | cli
    add_log_success "us" "Strong admin password set"
}

# 2. Disable SSH Management Access (if required)
disable_ssh_management() {
    echo "Disabling SSH management access..." | tee -a "$logfile"
    cli_command="set deviceconfig setting management ssh no"
    echo "$cli_command" | cli
    add_log_success "us" "SSH management disabled"
}

# 3. Restrict Management Access (only specific IPs)
restrict_management_access() {
    echo "Restricting management access to allowed IPs..." | tee -a "$logfile"
    cli_command="set deviceconfig system permitted-ip $allowed_ips"
    echo "$cli_command" | cli
    add_log_success "us" "Restricting management access to allowed IP: ${allowed_ips}"
}

# 4. Configure Logging for All Rules
enable_logging_for_rules() {
    echo "Enabling logging for all security rules..." | tee -a "$logfile"
    cli_command="set rulebase security rules all log-start yes; set rulebase security rules all log-end yes"
    echo "$cli_command" | cli
    add_log_success "us" "Setting logging for all security rules "
}

# 5. Set Minimum TLS Version (to enforce strong TLS policies)
set_tls_version() {
    echo "Enforcing TLSv1.2 and above..." | tee -a "$logfile"
    cli_command="set deviceconfig setting ssl tlsv1.2 enable yes"
    echo "$cli_command" | cli
    add_log_success "us" "Setting TLSv1.2 and above"
}

# 6. Enable Threat Prevention Profiles
enable_threat_prevention() {
    echo "Enabling threat prevention profiles..." | tee -a "$logfile"
    cli_command="set rulebase security rules all profile-setting profiles antivirus default"
    echo "$cli_command" | cli
    cli_command="set rulebase security rules all profile-setting profiles vulnerability default"
    echo "$cli_command" | cli
    cli_command="set rulebase security rules all profile-setting profiles spyware default"
    echo "$cli_command" | cli
    cli_command="set rulebase security rules all profile-setting profiles url-filtering default"
    echo "$cli_command" | cli
    add_log_success "us" "Setting threat prevention profiles"
}

# 7. Assign Interfaces to Zones
assign_interfaces_to_zones() {
    echo "Assigning interfaces to zones..." | tee -a "$logfile"
    add_log_info "us" "Assigning interfaces to zones"
    interfaces=$(cli -c "show interface all" | awk '/ethernet/{print $1}')
    zone_names=("external" "internal" "public" "user")
    index=0
    for interface in $interfaces; do
        if [ $index -lt ${#zone_names[@]} ]; then
            zone=${zone_names[$index]}
            echo "Assigning interface $interface to zone $zone..." | tee -a "$logfile"
            cli_command="set network interface $interface zone $zone"
            echo "$cli_command" | cli
            index=$((index+1))
            add_log_success "us" "Assigning interface ${interface} to zone ${zone}"
        fi
    done
}

# 8. Apply Zone Protection Profiles
apply_zone_protection() {
    echo "Applying zone protection profiles..." | tee -a "$logfile"
    cli_command="set network zone untrust network layer3 enable-zone-protection yes"
    echo "$cli_command" | cli
    cli_command="set network zone trust network layer3 enable-zone-protection yes"
    echo "$cli_command" | cli
    add_log_success "us" "Applying zone protection profiles"
}

# 9. Block Unauthorized Applications
block_unauthorized_applications() {
    echo "Blocking unauthorized applications..." | tee -a "$logfile"
    cli_command="set rulebase security rules block-applications action deny"
    echo "$cli_command" | cli
    cli_command="set rulebase security rules block-applications application any"
    echo "$cli_command" | cli
    add_log_success "us" "Blocking unauthorized applications"
}

# 10. Enable DNS Security
enable_dns_security() {
    echo "Enabling DNS Security..." | tee -a "$logfile"
    cli_command="set deviceconfig setting dns-security enable yes"
    echo "$cli_command" | cli
    add_log_success "us" "Set DNS Security"
}

# 11. Configure SSL Decryption with Self-Signed Certificate
configure_ssl_decryption() {
    echo "Configuring SSL Decryption..." | tee -a "$logfile"
    cli_command="set shared certificate ssl-decrypt-cert common-name SSL_Decryption_Cert generate-key yes"
    echo "$cli_command" | cli
    cli_command="set shared ssl-decryption ssl-inbound-inspection enable yes"
    echo "$cli_command" | cli
    cli_command="set shared ssl-decryption ssl-forward-proxy enable yes"
    echo "$cli_command" | cli
    add_log_success "us" "Set SSL Decryption"
}

# 12. Save Configuration
save_configuration() {
    echo "Saving configuration..." | tee -a "$logfile"
    cli_command="commit"
    echo "$cli_command" | cli
    add_log_success "us" "Confguration saved"
}

# Execute the tasks
enter_config_mode
set_admin_password_policy
disable_ssh_management
restrict_management_access
enable_logging_for_rules
set_tls_version
enable_threat_prevention
assign_interfaces_to_zones
apply_zone_protection
block_unauthorized_applications
enable_dns_security
configure_ssl_decryption
save_configuration

echo "Palo Alto Network automation and hardening completed successfully!" | tee -a "$logfile"
add_log_success "us" "Palo Alto Network automation and hardening completed successfully!"
exit 0

