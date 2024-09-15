#!/usr/bin/env bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

ops="$@"
cmd="${ops[*]}"
cmd="${cmd//x/*}"
cmd="${cmd//[/(}"
cmd="${cmd//]/)}"
log::debug "Calculating: ${cmd}"
result="$(lib::exec echo "${cmd}" | bc -l)"
echo "$result"
echo "$result" | xclip -sel clip
