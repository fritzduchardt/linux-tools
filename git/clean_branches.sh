#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

# Quick script to purge all the branches that have been merged to a target
# branch (defaults to master)
mergeInto="${1:-main}"
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
