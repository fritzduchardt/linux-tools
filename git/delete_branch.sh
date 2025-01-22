#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

delete_branch="${1:?Please provide branch to delete}"
main="$(find_main_branch)"
current_branch="$(find_current_branch)"

if [[ "$delete_branch" == "$main" ]]; then
  log::error "Please don't delete $main. You are gonna need it!"
  exit 2
fi

if [[ "$current_branch" != "$main" ]]; then
  lib::exec git checkout "$main"
fi

if ! lib::exec git push origin --delete "$delete_branch" 2>/dev/null; then
  log::error "Could not delete remote branch. Probably was deleted already"
fi

if ! lib::exec git branch -D "$delete_branch" 2>/dev/null; then
  log::error "Could not delete local branch. Probably was deleted already"
fi
