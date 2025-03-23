#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

cmd="$*"
cmd="${cmd//x/*}"
cmd="${cmd//[/(}"
cmd="${cmd//]/)}"
log::debug "Calculating: $cmd"
result="$(lib::exec echo "$cmd" | bc -l)"
echo "$result"
echo "$result" | xclip -sel clip
