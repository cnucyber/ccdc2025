#!/bin/bash

# This is used for creating logs of what the script is doing.

src_dir=$(dirname "$(realpath "$0")")

source "${src_dir}/common/basicFunctions.sh"

host=$(hostname)

create_log() {
  touch "${host}.log"
  blue_text "Creating logs for ${host} at $(date +'%I:%M:%S %p')"
  blue_text "|info|${host}@$(date +'%I:%M:%S %p')| Start of logs for ${host} at $(date +'%I:%M:%S %p')" >> "${host}.log"
}

add_log_info() {
  text=$1
  blue_text "|info|${host}@$(date +'%I:%M:%S %p')| ${text}" >> "${host}.log"
}

add_log_success() {
  text=$1
  green_text "|succ|${host}@$(date +'%I:%M:%S %p')| ${text}" >> "${host}.log"
}

add_log_warn() {
  text=$1
  yellow_text "|warn|${host}@$(date +'%I:%M:%S %p')| ${text}" >> "${host}.log"
}

add_log_critical() {
  text=$1
  red_text "|crit|${host}@$(date +'%I:%M:%S %p')| ${text}" >> "${host}.log"
}
