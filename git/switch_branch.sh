#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

function help() {
  echo "Usage: $(basename "$0") <branch_name>"
  echo
  echo "Switch to a new or existing branch"
  echo
  echo "Arguments:"
  echo "  branch_name    Name of the branch to switch to"
  echo
  echo "This script will:"
  echo "1. Stash any local changes"
  echo "2. Switch to the main branch and pull latest changes if not already on main"
  echo "3. Create the new branch if it doesn't exist, or switch to it if it does"
  echo "4. Pop the stash if changes were stashed"
}

function main() {
  local new_branch main current stashed
  
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help
    exit 0
  fi
  
  # Check if in a git repository
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
}

main "$@"

