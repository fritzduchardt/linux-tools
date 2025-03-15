#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

FBRC_BIN="$SCRIPT_DIR/fabric.sh"

# fbrcs
function fbrc_improve() {
  local file session line continue_arg
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -i)
        file="$2"
        shift 2
        ;;
      -s)
        session="$2"
        shift 2
        ;;
      -c | --continue)
        continue_arg="-c"
        shift 1
        ;;
      *)
        log::error "Invalid option: $1"
        shift 1
        break
        ;;
    esac
  done

  if [[ -z  "$file" ]]; then
    while IFS= read -r line; do
      log::info "Improving $line"
      lib::exec "$FBRC_BIN" -p devops_improve -i "$line" -o -s "$session" $continue_arg
    done
  else
      log::info "Improving $file"
      lib::exec "$FBRC_BIN" -p devops_improve -i "$file" -o -s "$session" $continue_arg
  fi
}

fbrc_improve "$@"
