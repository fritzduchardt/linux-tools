#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"

help() {
  local help selection
  if [[ $# -eq 0 ]]; then
    log::error "Command is missing"
    exit 2
  fi

  if man "$1" >/dev/null 2>&1; then
    help="$(man "$1" | col -b | tac)"
  elif ! help="$("$@" --help | tac)"; then
    exit 2
  fi

  selection="$(fzf -e <<<"$help")"
  echo "$help" | grep -A3 "$selection"
}

help "$@"
