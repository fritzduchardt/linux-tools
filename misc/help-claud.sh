#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"

usage() {
    echo "Usage: $0 <command>"
    echo "Displays interactive help for the specified command"
    echo
    echo "Options:"
    echo "  command    The command to get help for"
    echo
    echo "Example:"
    echo "  $0 ls     # Show interactive help for ls command"
    exit 1
}

help() {
  local help selection
  if [[ $# -eq 0 ]]; then
    usage
  fi

  if ! help="$("$@" --help | tac)"; then
    exit 2
  fi

  selection="$(fzf -e <<<"$help")"
  echo "$help" | grep -A3 "$selection"
}

help "$@"
