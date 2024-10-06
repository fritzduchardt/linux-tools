#!/usr/bin/env bash
set -eo pipefail

source "../lib/log.sh"
source "../lib/utils.sh"
source "./git_lib.sh"

new_branch="${1:?Provide new branch name}"
main="$(find_main_branch)"

lib::exec git stash --all
if [[ "$(lib::exec git branch --show-current)" != "$main" ]]; then
  lib::exec git switch "$main"
  lib::exec git pull
fi
if [[ -z "$(lib::exec git branch --list "$new_branch")" ]]; then
  lib::exec git switch -c "$new_branch"
else
  lib::exec git switch "$new_branch"
fi
lib::exec git stash pop
