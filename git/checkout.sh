#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

# list remote and local branches in order to check them out
function checkout_branches() {
  local branch="$1"
  local branches
  branches="$(lib::exec git branch -a | tr -d ' ')"
  echo "$branches" | fzf --query "$branch" --preview 'git log -n 10 --color=always --oneline --abbrev-commit {}' | sed "s/remotes\/origin\///g" | xargs git checkout
}

checkout_branches "$1"
