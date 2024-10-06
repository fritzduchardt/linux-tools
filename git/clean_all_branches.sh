#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

delete_remote="${1}"
main="$(find_main_branch)"
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
