#!/usr/bin/env bash

XCLIP_COPY=(xclip -r -sel clip)
XCLIP_PASTE=(xclip -sel clip -o)
OUTPUT_FILTER=(grep -v "Creating new session:")

last_fabric() {
     grep -o -E "^fabric .*" ~/.bash_history | tac | head -n1
}

last_session() {
  local -r cmd="$(last_fabric)"
  echo "$cmd" | grep -o -E "\-\-session \w+" | sed -E "s/--session\s+//"
}
