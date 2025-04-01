#!/usr/bin/env bash

set -euo pipefail

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

  if man "$@" >/dev/null 2>&1; then
    help="$(man "$@" | col -b | tac)"
  elif ! help="$("$@" --help | tac)"; then
    log::error "Failed to get help output for $*"
    exit 2
  fi

  if ! selection="$(fzf -e <<<"$help")"; then
    log::error "Failed to get selection from fzf"
    exit 3
  fi

  grep -A3 "$selection" <<<"$help"
}

help "$@"
