#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"

usage() {
  log::info "Usage: $0 <command>"
  exit 1
}

help() {
  local help selection

  if [[ $# -eq 0 ]]; then
    usage
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
