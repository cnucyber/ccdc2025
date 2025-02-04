#!/bin/bash

# This is used for detecting the os

src_dir=$(dirname "$(realpath "$0")")
source "${src_dir}/common/basicFunctions.sh"
source "${src_dir}/common/scriptLoger.sh"

detect_os() {
  blue_text "Detecting os"
  distro=$(hostnamectl | grep "Operating System" | awk '{print $3}')
  add_log_info "Detected distro: ${distro}" 
  if [ "$distro" = "Ubuntu" ] ||[ "$distro" = "Debian" ] ||[ "$distro" = "LinuxMint" ] ; then
    distotype="deb"
    add_log_info "Selected distro type: ${distotype}"
  elif [ "$distro" = "Fedora" ] ||[ "$distro" = "Redhat" ] ||[ "$distro" = "Rocky" ] ; then
    distotype="red"
    add_log_info "Selected distro type: ${distotype}"
  else
    yellow_text "Distro not recgonized please select family:"
    printf "0.| Debiain \n1.| Redhat\n"
    while true; do
      read -r distro_input
      if [ "$distro_input" = "0" ]; then
        distotype="deb"
        add_log_warn "Distro family manualy selected as: ${distotype}"
        break
      elif [ "$distro_input" = "1" ]; then
        distotype="red"
        add_log_warn "Distro family manualy selected as: ${distotype}"
        break
      else
        continue
      fi
    done
  fi
  packed_info=("$distro" "$distotype" )
  echo "${packed_info[@]}"
}
