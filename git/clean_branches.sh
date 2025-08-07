#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

function help() {
  echo "Usage: $(basename "$0")"
  echo
  echo "Clean all merged branches"
  echo
  echo "This script deletes all local branches that have been merged into the main branch."
  echo "It automatically detects the main branch (main, trunk, master, etc.)."
}

function main() {
  local mergeInto branches
  
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help
    exit 0
  fi
  
  mergeInto="$(find_main_branch)"
  if ! lib::exec git checkout "$mergeInto"; then
    log::error "Failed to checkout $mergeInto"
    exit 1
  fi
  
  log::info "Merge Target: $mergeInto"
  branches="$(lib::exec git branch --merged "$mergeInto" | grep -v "^[*+]")"
  if [[ -z "$branches" ]]; then
    log::info "No branches to delete"
    exit 0
  fi

  echo "$branches" | xargs -r git branch -d
}

main "$@"

