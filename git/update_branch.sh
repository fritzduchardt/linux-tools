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

lib::exec git stash push --include-untracked
lib::exec git fetch
lib::exec git rebase "origin/$main"
lib::exec git stash pop
