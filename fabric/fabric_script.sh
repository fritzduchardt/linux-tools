#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

FBRC_BIN="$SCRIPT_DIR/fabric.sh"

# fbrcs
function fbrc_script() {
  local line dir file desc path session
  session="$(date +%Y%m%d%H%M%S)"
  trap "fabric --wipesession=$session" EXIT
  while IFS= read -r line; do
    path="${line%--*}"
    desc="${line#*-- }"
    file="${path##*/}"
    dir="${path%/*}"
    echo "desc: $desc"
    echo "file: $file"
    echo "dir: $dir"
    mkdir -p "$dir"
    if [[ "$file" != "" ]]; then
      "$FBRC_BIN" devops_script -s "$session" "$desc" > "$path"
    fi
  done
}

fbrc_script "$@"
