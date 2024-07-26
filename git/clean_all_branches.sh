#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

main="${1:-master}"
delete_remote="${2}"
lib::exec git checkout "$main"
while read -r branch; do
  lib::prompt "Delete $branch"
  if [[ -n $delete_remote ]]; then
    lib::exec git checkout "$branch" &>/dev/null
    if lib::exec git push origin --delete "$branch" &>/dev/null; then
      log::info "Deleted on remote as well"
    fi
    lib::exec git checkout "$main" &>/dev/null
  fi
  lib::exec git branch -D "$branch"
done < <(lib::exec git branch | grep -vw "$main")
log::info "Finished"
