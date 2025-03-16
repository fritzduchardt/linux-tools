#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"

# MINOR: Added a usage function to provide a guide for using the script
usage() {
  echo "Usage: $0 <command>"
  echo
  echo "This script provides a help viewer for the specified command."
  echo "It reverses the help output, allows selection via fzf, and displays"
  echo "the selected help section with three lines of context."
  echo
  echo "Arguments:"
  echo "  <command>  The command to display help for."
  echo
  echo "Example:"
  echo "  $0 git"
}

help() {
  local help selection
  if [[ $# -eq 0 ]]; then
    log::error "Command is missing"
    usage
    exit 2
  fi

  if ! help="$("$@" --help | tac)"; then
    exit 2
  fi

  selection="$(fzf -e <<<"$help")"
  echo "$help" | grep -A3 "$selection"
}

# MINOR: Added a check to display usage when no arguments are provided
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

help "$@"
