#!/bin/bash

# This is used for creating logs of what the script is doing.
red_start="\033[31m"
color_end="\033[0m"
blue_start="\033[34m"
green_start="\033[32m"
yellow_start="\033[1;33m"
src_dir=$(dirname "$(realpath "$0")")
host=$(hostname)

green_text() {
  text=$1
  echo -e "${green_start}$text${color_end}"
}

blue_text() {
  text=$1
  echo -e "${blue_start}$text${color_end}"
}

red_text() {
  text=$1
  echo -e "${red_start}$text${color_end}"
}

yellow_text() {
  text=$1
  echo -e "${yellow_start}$text${color_end}"
}

create_log() { 
  touch "${host}.csv"
  green_text "Creating logs for ${host} at $(date +'%I:%M:%S %p')"
  green_text "succ,${host},$(date +'%I:%M:%S %p'),Start of logs for ${host} at $(date +'%I:%M:%S %p')" >> "${host}.csv"
}

add_log_info() {
  type=$1
  text=$2
  blue_text "info,${host},$(date +'%I:%M:%S %p'),${type},${text}" >> "${host}.csv"
}

add_log_success() {
  type=$1
  text=$2
  green_text "succ,${host},$(date +'%I:%M:%S %p'),${type},${text}" >> "${host}.csv"
}

add_log_warn() {
  type=$1
  text=$2
  yellow_text "warn,${host},$(date +'%I:%M:%S %p'),${type},${text}" >> "${host}.csv"
}

add_log_critical() {
  type=$1
  text=$2
  red_text "crit,${host},$(date +'%I:%M:%S %p'),${type},${text}" >> "${host}.csv"
}

clean_up() {
  truncate -s 0 "${host}.csv"
}

test_neutered() {
  create_log
  add_log_info "user" "info"
  add_log_success "us" "success"
  add_log_warn "system" "warn"
  add_log_critical "admin" "critical"
  rm "${host}.csv" 
}

test() {
  create_log
  add_log_info "user" "info"
  add_log_success "us" "success"
  add_log_warn "system" "warn"
  add_log_critical "admin" "critical"
  clean_up
}

"$@"

