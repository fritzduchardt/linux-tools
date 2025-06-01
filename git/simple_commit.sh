#!/usr/bin/env bash
set -eo pipefail

# Set script directory and source required libraries
SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

main() {
  local mr force push msg ai msg_proposal prefix_choices prefix cmd main_branch current_branch all opt

  # Parse command line arguments using getopts
  while getopts "mMfpa" opt; do
    case $opt in
      m) mr="yes" ;;
      M) mr="no" ;;
      f) force="yes" ;;
      p) push="yes" ;;
      a) all="yes" ;;
      *) exit 1 ;;
    esac
  done
  shift $((OPTIND-1))

  msg="$*"

  # Check for changes
  if [[ -z "$(git status --porcelain)" ]]; then
    log::info "Nothing to commit"
    exit 1
  fi

  # Stage all files if nothing is staged
  if [[ "$all" == "yes" || -z "$(git diff --staged)" ]]; then
    lib::exec git add .
  fi

  # Handle commit message generation
  if [[ -z "$msg" ]]; then
    log::info "Figuring out your commit message.."
    msg_proposal=$(mktemp)
    trap "rm -f $msg_proposal" EXIT
    git diff --staged | "$SCRIPT_DIR/../../ai-tools/fabric/fabric.sh" -p devops_gitcommit > "$msg_proposal"
    vim "$msg_proposal"
    msg=$(cat "$msg_proposal")
    ai=true
    if [[ -z "$msg" ]]; then
      log::error "Please provide commit message"
      exit 2
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

  log::info "Committing.."
  lib::exec git commit -m "$msg"

  if [[ "$push" == "yes" ]]; then
    log::info "Pushing.."
    cmd=(git push origin HEAD)
    if [[ "$mr" == "yes" ]]; then
      log::info "..with MR.."
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
  log::info "Done!"
}

main "$@"
