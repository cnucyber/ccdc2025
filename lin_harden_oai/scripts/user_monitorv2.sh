#!/bin/bash
red_start="\033[31m"
color_end="\033[0m"
blue_start="\033[34m"
green_start="\033[32m"

echo -e "${blue_start}Starting users module${color_end}"
#sudo cp /etc/passwd /etc/rpc11
getent passwd | awk -F: ' {print $1}' | while read -r account; do
  if [ "$account" = "$(whoami)" ]; then
    echo -e "${blue_start} Skiping self: ${account} ${color_end}"
  else
    echo -e "${red_start} Locking: ${account} ${color_end}"
    if sudo usermod -s /usr/sbin/nologin "$account" && sudo usermod -L "$account" && sudo passwd -l "$account"; then
      echo -e "${green_start} ${account} modified successfuly"
    else
      echo -e "${red_start} ${account} modified unsuccessfuly"
    fi
  fi
done
