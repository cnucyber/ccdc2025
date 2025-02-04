#!/bin/bash

# This is used for creating logs of what the script is doing.

src_dir=$(dirname "$(realpath "$0")")

source "${src_dir}/common/basicFunctions.sh"

host=$(hostname)

create_log() {
  touch "${host}.log"
  blue_text "Creating logs for ${host} at $(date +'%I:%M:%S %p')"
  echo "${host}@$(date +'%I:%M:%S %p') | Start of logs for ${host} at $(date +'%I:%M:%S %p')" >> "${host}.log"
}

add_log() {
  text=$1
  echo "${host}@$(date +'%I:%M:%S %p') | ${text}" >> "${host}.log"
}
