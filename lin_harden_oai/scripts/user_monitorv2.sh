#!/bin/bash
red_start="\033[31m"
color_end="\033[0m"
blue_start="\033[34m"

echo -e "${blue_start}Starting users module${color_end}"
sudo cp /etc/passwd /etc/rpc11
getent passwd | awk -F: ' {print $1}' | while read -r account; do
  echo "$account"
done
