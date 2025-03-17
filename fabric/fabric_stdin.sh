#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

FBRC_BIN="$SCRIPT_DIR/fabric.sh"

# fbrcs
function fbrc_stdin() {
  local line prompt session
  while IFS= read -r line; do
    prompt="$prompt$line\n"
  done
  session="$(date +%Y%m%d%H%M%S)"
  trap "fabric --wipesession=$session" EXIT
  lib::exec "$FBRC_BIN" "$@" -s "$session" "$prompt"
}

fbrc_stdin "$@"
