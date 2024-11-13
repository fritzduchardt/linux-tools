#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

main="$(find_main_branch)"
current="$(find_current_branch)"

if [[ "$current" == "$main" ]]; then
  lib::exec git pull
fi

local_changes=""
if [[ -n "$(git status --porcelain)" ]]; then
  log::info "Stashing local changes"
  lib::exec git stash push --include-untracked
  local_changes="true"
fi
lib::exec git fetch
log::info "Rebase with origin/$main"
lib::exec git rebase "origin/$main"
if [[ -n "$local_changes" ]]; then
  log::info "Restoring local changes"
  lib::exec git stash pop
fi
