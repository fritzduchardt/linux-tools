#!/usr/bin/env bash

set -eo pipefail
SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/fabric_lib.sh"

FBRC_BIN="$SCRIPT_DIR/fabric_stdin.sh"

function fbrc_amend_project() {

  local line file_name
  while IFS= read -r line; do
    if [[ "$line" == "FILENAME:"* ]]; then
      file_name="${line#*FILENAME: }"
      log::info "Writing $file_name"
      if ! lib::exec truncate -s 0 "$file_name"; then
        touch "$file_name"
      fi
    else
      if [[ -n "$file_name" ]]; then
        echo "$line" >> "$file_name"
      else
        log::info "$line"
      fi
    fi
  done < <(lib::exec "$FBRC_BIN" -p devops_amend_project "$@")

  log::info "Done!"
}

fbrc_amend_project "$@"
