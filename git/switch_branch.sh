#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

# MINOR: Added check for git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log::error "Not a git repository"
    exit 1
fi

new_branch="${1:?Provide new branch name}"
main="$(find_main_branch)"
current="$(find_current_branch)"

if [[ -n "$(git status --porcelain)" ]]; then
    lib::exec git stash --all
    stashed=true
fi

if [[ "$current" != "$main" ]]; then
    lib::exec git switch "$main"
    lib::exec git pull --ff-only
fi

if ! git branch --list "$new_branch" >/dev/null; then
    lib::exec git switch -c "$new_branch"
else
    lib::exec git switch "$new_branch"
fi

if [[ "$stashed" == true ]]; then
    lib::exec git stash pop
fi
