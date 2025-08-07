#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

function help() {
  echo "Usage: $(basename "$0")"
  echo
  echo "Update the current branch with latest changes from main"
  echo
  echo "This script will:"
  echo "1. Stash any local changes"
  echo "2. If on main branch, pull latest changes"
  echo "3. If on another branch, fetch and rebase from origin/main"
  echo "4. Restore any stashed changes"
}

function main() {
  local main current local_changes
  
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help
    exit 0
  fi
  
  main="$(find_main_branch)"
  current="$(find_current_branch)"

  local_changes="false"
  if [[ -n "$(git status --porcelain)" ]]; then
    log::info "Stashing local changes"
    lib::exec git stash push --include-untracked
    local_changes="true"
  fi
  
  if [[ "$current" == "$main" ]]; then
    lib::exec git pull
  else
    lib::exec git fetch
    log::info "Rebase with origin/$main"
    lib::exec git rebase "origin/$main"
  fi
  
  if [[ "$local_changes" == "true" ]]; then
    log::info "Restoring local changes"
    lib::exec git stash pop
  fi
}

main "$@"
