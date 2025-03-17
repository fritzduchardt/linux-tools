#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

while getopts "mfan" opt; do
  case $opt in
    m) mr="yes" ;;
    f) force="yes" ;;
    n) no_push="yes" ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND-1))

msg="$*"
ai=""
if [[ -z "$msg" ]]; then
  log::info "Figuring out your commit message.."
  msg_proposal=$(mktemp)
  trap "rm $msg_proposal" EXIT
  git diff --staged | "$SCRIPT_DIR/../fabric/fabric_stdin.sh" -p devops_gitcommit > "$msg_proposal"
  vim "$msg_proposal"
  msg=$(cat "$msg_proposal")
  ai=true
  if [[ -z "$msg" ]]; then
    log::error "Please provide commit message"
    exit 1
  fi
fi

if [[ -z "$ai" ]]; then
  prefix_choices="fix\nfeat\ndocs\nchore"
  prefix="$(echo -e "$prefix_choices" | fzf)"
  msg="$prefix: $msg"
fi

if [[ -z "$mr" ]]; then
  mr="$(echo -e "no\nyes" | fzf --header "MR")"
fi

lib::exec git commit -m "$msg"

if [[ "$no_push" != "yes" ]]; then
  cmd=(git push origin HEAD)
  if [[ "$mr" == "yes" ]]; then
    main_branch="$(find_main_branch)"
    current_branch="$(find_current_branch)"
    if [[ "$current_branch" == "$main_branch" ]]; then
      log::error "You are on $main_branch"
      exit 2
    fi
    cmd+=(-o merge_request.create)
  fi
  if [[ "$force" == "yes" ]]; then
    cmd+=(-f)
  fi
  lib::exec "${cmd[@]}"
fi
