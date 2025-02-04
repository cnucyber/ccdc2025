#!/bin/bash 

# This is the starting place of our main script and it is only used for linking files.

# sourcing files
source "./common/basicFunctions.sh"
source "./common/scriptLoger.sh"
source "./modules/os_detector.sh"

main() {
  blue_text "Source dir: $src_dir"
  create_log
  add_log_info "Source dir: $src_dir"
  add_log_success "Success"
  add_log_warn "Warning"
  add_log_critical "Critical"
  detect_os
  picker
}

picker() {

}


main

