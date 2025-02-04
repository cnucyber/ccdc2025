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
