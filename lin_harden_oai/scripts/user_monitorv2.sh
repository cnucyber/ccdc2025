#!/usr/bin/env bash
source "../../loggerUnified.sh"

lock_users() {
  blue_text "Starting users module"
  add_log_info "us" "Starting users module"
  sudo cp /etc/passwd /etc/rpc11
  getent passwd | awk -F: ' {print $1}' | while read -r account; do
    if [ "$account" = "$(whoami)" ]; then
      blue_text "Skiping self: ${account}"
      add_log_info "us" "Skiping motifing ${account} as it is running the lock user script"
    else
      red_text "Locking: ${account}"
      add_log_info "us" "Attempting to motify ${account}"
      if sudo usermod -s /usr/sbin/nologin "$account" && sudo usermod -L "$account" && sudo passwd -l "$account"; then
        green_text "${account} modified successfuly"
        add_log_success "us" "${account} modified successfuly"
      else
        red_text "${account} modified unsuccessfuly"
        add_log_warn "us" "${account} modified unsuccessfuly"
      fi
    fi
  done
}
monitor_users() {
  user_file="/etc/passwd"
  previous_mtime=$(stat -c %Y "$user_file")
  while true; do
    current_mtime=$(stat -c %Y "$user_file")
    if [ "$current_mtime" -gt "$previous_mtime" ]; then
      red_text "Alert: Passwd has been motified@${current_mtime}"
      add_log_critical "admin" "Alert: Passwd has been modified!@${current_mtime}"
      previous_mtime="$current_mtime"
    fi
    sleep 1
  done
}
"$@"

