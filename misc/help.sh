#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  log::info "Usage: $0 <command>"
  exit 1
}

help() {
  local help selection

  if [[ $# -eq 0 ]]; then
    usage
  fi

  local type="help"
  local -r tempfile="$(mktemp)"
  if man "$@" >/dev/null 2>&1; then
    type="man"
    lib::exec man "$@" | col -b | tac >"$tempfile"
  else
    "$@" --help | tac >"$tempfile"
  fi

  lib::exec fzf -e \
    --prompt "$type > " \
    --border \
    --height "80%" \
    --preview "grep -A 100 {} $tempfile" \
    <"$tempfile" >/dev/null
}

help "$@"
