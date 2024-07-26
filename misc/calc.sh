#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

ops="$@"
log::debug "Calculating: ${ops[*]}"
result="$(lib::exec echo $((${ops[@]})))"
echo "$result"
# echo "$result" | xclip -sel clip
