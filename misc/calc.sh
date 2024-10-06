#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

ops="$*"
cmd="${ops[*]}"
cmd="${cmd//x/*}"
cmd="${cmd//[/(}"
cmd="${cmd//]/)}"
log::debug "Calculating: ${cmd}"
result="$(lib::exec echo "${cmd}" | bc -l)"
echo "$result"
echo "$result" | xclip -sel clip
