#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

function help() {
  echo "Usage: $(basename "$0") [true|false]"
  echo
  echo "Clean all branches except the main branch"
  echo
  echo "Arguments:"
  echo "  true|false    Whether to delete remote branches as well (default: false)"
  echo
  echo "This script will prompt for confirmation before deleting each branch."
}

function main() {
  local delete_remote="${1:-false}"
  local main
  
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help
    exit 0
  fi
  
  main="$(find_main_branch)"
  if [[ -z "$main" ]]; then
    log::error "Main branch not found"
    exit 1
  fi
  
  lib::exec git checkout "$main"
  while read -r branch; do
    if lib::prompt "Delete $branch"; then
      if [[ "$delete_remote" == "true" ]]; then
        log::info "Delete branch: $branch"
        lib::exec git branch -D "$branch"
        if lib::exec git push origin --delete "$branch" &>/dev/null; then
          log::info "Deleted on remote branch as well"
        fi
      fi
    fi
  done < <(lib::exec git branch | grep -vw "$main")
  log::info "Finished"
}

main "$@"

