#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

function checkout_branches() {
  local branch="$1" co_branch branches
  branches="$(lib::exec git branch -a --sort=-committerdate | tr -d ' ')"
  co_branch="$(echo "$branches" | fzf --query "$branch" --preview 'git log -n 10 --color=always --oneline --abbrev-commit {}' | sed "s/remotes\/origin\///g")"
  if [[ -n "$co_branch" ]]; then
    git checkout "$co_branch"
  fi
}

checkout_branches "$1"
