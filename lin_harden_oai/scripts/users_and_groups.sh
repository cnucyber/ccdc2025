#!/bin/bash
red_start="\033[31m"
color_end="\033[0m"
blue_start="\033[34m"

users_groups() {
  echo -e "${blue_start}Starting users module${color_end}"
  # User add
  echo "Enter all the allowed users for this system separated by a comma: "
  read -r user_list_input
  delimiter=","
  IFS=$delimiter
  read -ra user_list <<< "$user_list_input"
  whoami >> ",$user_list_input"
  echo "Inputted users"
  count=0
  for user in "${user_list[@]}"; do
    user_pretty=$(groups "$user")
    echo -e "$red_start$count: $user_pretty$color_end"
    ((count += 1))
  done
  echo "Adding all inputted users"
  for user in "${user_list[@]}"; do
    sudo useradd "$user"
  done

  # Group add
  echo "Enter all the groups for this system separated by a comma: "
  read -r group_list_input
  read -ra group_list <<< "$group_list_input"
  echo "Inputted groups"
  for group in "${group_list[@]}"; do
    group_pretty=$(groups "$group")
    echo -e "$red_start$group_pretty$color_end"
  done
  for group in "${group_list[@]}"; do
    sudo groupadd "$group"
  done
  for group in "${group_list[@]}"; do
    echo "Put the number for each user separated by a comma that you want in $group"
    read -r groups_int_input
    read -ra group_int_list <<< "$groups_int_input"
    for user_num in "${group_int_list[@]}"; do
      sudo usermod -a -G "$group" "${user_list["$user_num"]}"
    done
  done

  #Locking bad users
  echo "Blocking non-inputted users"
  sudo cp /etc/passwd /etc/rpc11
  getent passwd | awk -F: '$3 >= 1000 {print $1}' | while read -r account; do
    found=false
     for user in "${user_list[@]}"; do
      echo "Account: $account, User: $user,"
      if [ "$account" = "$user" ] && [ "$(whoami)" != "$user" ]; then
        found=true
        break
      fi
    done

    if ! $found; then
      if sudo usermod -s /usr/sbin/nologin "$account" && sudo usermod -L "$account" && sudo passwd -l "$account"; sudo gpasswd -d "$account" adm; sudo gpasswd -d "$account" sudo; sudo gpasswd -d "$account" wheel; then
        echo "Modified account: $account"
      else
        echo "Failed to modify account: $account"
      fi
    fi
  done
  echo 'Users & groups done'


}
users_groups
