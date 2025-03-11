#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

new_branch="${1:?Provide new branch name}"
main="$(find_main_branch)"
current="$(find_current_branch)"

lib::exec git stash --all
if [[ "$current" != "$main" ]]; then
  lib::exec git switch "$main"
  lib::exec git pull --ff-only
fi
if ! git branch --list "$new_branch" >/dev/null; then
  lib::exec git switch -c "$new_branch"
else
  lib::exec git switch "$new_branch"
fi
lib::exec git stash pop
