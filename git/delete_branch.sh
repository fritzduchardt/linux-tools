#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

function help() {
  echo "Usage: $(basename "$0") <branch_name>"
  echo
  echo "Delete a branch both locally and remotely"
  echo
  echo "Arguments:"
  echo "  branch_name    Name of the branch to delete"
  echo
  echo "This script will delete the specified branch both locally and remotely."
  echo "It will not allow deletion of the main branch."
}

function main() {
  local delete_branch main current_branch
  
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help
    exit 0
  fi
  
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
}

main "$@"

