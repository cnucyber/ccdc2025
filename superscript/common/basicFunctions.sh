#!/bin/bash

# Used for coloring text in the script

red_start="\033[31m"
color_end="\033[0m"
blue_start="\033[34m"
green_start="\033[32m"
yellow_start="\033[1;33m"

src_dir=$(dirname "$(realpath "$0")")
export src_dir

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


