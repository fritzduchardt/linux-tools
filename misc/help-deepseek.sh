#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"

help() {
  local help selection
  if [[ $# -eq 0 ]]; then
    log::error "Command is missing"
    exit 2
  fi

  if ! help="$("$@" --help | tac)"; then
    exit 2
  fi

  selection="$(fzf -e <<<"$help")"
  echo "$help" | grep -A3 "$selection"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0 <command>"
  exit 0
fi

help "$@"
