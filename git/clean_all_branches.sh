#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

delete_remote="$1"
main="$(find_main_branch)"
if [[ -n "$main" ]]; then
  log::error "Main branch not found"
  exit 1
fi
lib::exec git checkout "$main"
while read -r branch; do
  lib::prompt "Delete $branch"
  if [[ "$delete_remote" == "true" ]]; then
    if lib::exec git push origin --delete "$branch" &>/dev/null; then
      log::info "Deleted on remote as well"
    fi
  fi
  lib::exec git branch -D "$branch"
done < <(lib::exec git branch | grep -vw "$main")
log::info "Finished"
