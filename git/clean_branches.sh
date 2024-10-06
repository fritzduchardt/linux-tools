#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"
source "./git_lib.sh"

# Quick script to purge all the branches that have been merged to a target
# branch (defaults to master)
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
while read -r branch; do
  lib::exec git branch -d "$branch"
done <<<"$branches"
