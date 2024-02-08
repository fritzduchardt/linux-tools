#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

# Quick script to purge all the branches that have been merged to a target
# branch (defaults to master)
mergeInto="${1:-main}"
currentBranch=$(git symbolic-ref --short HEAD)
log::info "Merge Target: $mergeInto"
log::info "Current Branch: $currentBranch"
if [[ "$currentBranch" != "$mergeInto" ]]; then
  log::error "You have to be on the same git branch you're using as the merge target"
  exit 1
fi
lib::exec git branch --merged "$mergeInto" | grep -v "^[*+]" | xargs -n 1 git branch -d
