#!/usr/bin/env bash

git::clean_branches() {
  # Quick script to purge all the branches that have been merged to a target
  # branch (defaults to master)
  if [[ $# != 1 ]]; then
    mergedInto="main"
  else
    mergedInto="$1"
  fi
  currentBranch=$(git symbolic-ref --short HEAD)
  if [[ "${currentBranch}" != "${mergedInto}" ]]; then
    echo "You have to be on the same git branch you're using as the merge target"
    exit 1
  fi
  git branch --merged "${mergedInto}" | grep -v "^[*+]" | xargs -n 1 git branch -d
}
