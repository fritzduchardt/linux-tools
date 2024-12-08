#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

msg="$*"
if [[ -z "$msg" ]]; then
  log::error "Please provide commit message"
  exit 1
fi
prefix="$(echo -e "fix\nfeat\ndocs\nchore" | fzf)"
mr="$(echo -e "no\nyes" | fzf --header "MR")"
force="$(echo -e "no\nyes" | fzf --header "force")"

cmd=(git push origin HEAD)
if [[ "$mr" == "yes" ]]; then
  main_branch="$(find_main_branch)"
  if [[ "$(find_current_branch)" == "$main_branch" ]]; then
    log::error "You are on $main_branch"
    exit 2
  fi
  cmd+=(-o merge_request.create)
fi
if [[ "$force" == "yes" ]]; then
  cmd+=(-f)
fi
lib::exec git add --all
lib::exec git commit -m "$prefix: $msg"
lib::exec "${cmd[@]}"
