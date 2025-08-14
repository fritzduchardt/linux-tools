#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

function help() {
  echo "Usage: $(basename "$0") [branch_name]"
  echo
  echo "Interactive branch checkout utility using fzf"
  echo
  echo "Arguments:"
  echo "  branch_name    Optional search term to filter branches"
  echo
  echo "This script shows a list of branches sorted by commit date and"
  echo "allows you to select one to check out."
}

function checkout_branches() {
  local branch="$1" co_branch branches

  branches="$(lib::exec git branch -a --sort=-committerdate | tr -d ' ')"
  co_branch="$(echo "$branches" | fzf --query "$branch" --preview 'git log -n 10 --color=always --oneline --abbrev-commit {}' | sed "s/remotes\/origin\///g")"
  if [[ -n "$co_branch" ]]; then
    git checkout "$co_branch"
  fi
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  help
  exit 0
fi

checkout_branches "$1"
