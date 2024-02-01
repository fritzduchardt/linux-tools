#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

# Quick script to purge all the branches that have been merged to a target
# branch (defaults to master)
if [[ $# != 1 ]]; then
  mergedInto="main"
else
  mergedInto="$1"
fi
currentBranch=$(git symbolic-ref --short HEAD)
log::info "currentBranch:$currentBranch"
if [[ "${currentBranch}" != "${mergedInto}" ]]; then
  echo "You have to be on the same git branch you're using as the merge target"
  exit 1
fi
lib::exec git branch --merged "${mergedInto}" | grep -v "^[*+]" | xargs -n 1 git branch -d
