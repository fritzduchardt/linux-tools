#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

FBRC_BIN="$SCRIPT_DIR/fabric.sh"

# fbrcs
function fbrc_improve() {
  local session="$1"
  local file="$2"
  local line session
  if [[ -z "$session" ]]; then
    session="$(date +%Y%m%d%H%M%S)"
    # shellcheck disable=SC2064
    trap "fabric --wipesession=$session" EXIT
  fi
  if [[ -z  "$file" ]]; then
    while IFS= read -r line; do
      log::info "Improving $line"
      "$FBRC_BIN" -p devops_improve -i "$line" -o -s "$session"
    done
  else
      log::info "Improving $file"
      "$FBRC_BIN" -p devops_improve -i "$file" -o -s "$session"
  fi
}

fbrc_improve "$@"
