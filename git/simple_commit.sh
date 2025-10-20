#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

help() {
  echo "Usage: $(basename "$0") [options] [commit message]"
  echo
  echo "Commit changes with optional AI-generated commit messages"
  echo
  echo "Options:"
  echo "  -m    Create merge request (yes)"
  echo "  -M    Don't create merge request (no)"
  echo "  -f    Force push"
  echo "  -p    Push after commit"
  echo "  -a    Stage all files before commit"
  echo "  -i    Use AI to suggest commit message (only executed when provided)"
  echo "  -h    Display this help message"
  echo
  echo "If no commit message is provided and -i is not passed, you will be prompted to enter one."
  echo
  echo "Examples:"
  echo "  $(basename "$0") -a -p -m \"fix: correct typo in README\""
  echo "  $(basename "$0") -a -p -i    # use AI to propose a commit message"
}

log::warn_to_warning() {
  # kept for compatibility if some lib uses log::warn
  log::warn "$1"
}

main() {
  local mr="" force="" push="" msg="" ai="" msg_proposal="" prefix_choices="" prefix="" cmd=() main_branch="" current_branch="" all="" branch_name="" branch_msg=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m) mr="yes"; shift ;;
      -M) mr="no"; shift ;;
      -f) force="yes"; shift ;;
      -p) push="yes"; shift ;;
      -a) all="yes"; shift ;;
      -i) ai="yes"; shift ;;
      -h|--help) help; exit 0 ;;
      --) shift; break ;;
      -*) log::error "Unknown option $1"; exit 1 ;;
      *) break ;;
    esac
  done

  msg="$*"

  if [[ -e ".git/index.lock" ]]; then
    lib::exec rm -f ".git/index.lock" || true
    log::warn "Removed git lock file"
  fi

  if [[ -z "$(lib::exec git status --porcelain)" ]]; then
    log::info "Nothing to commit"
    exit 1
  fi

  if [[ "$all" == "yes" || -z "$(lib::exec git diff --staged)" ]]; then
    lib::exec git add .
  fi

  if [[ -z "$msg" ]]; then
    if [[ "$ai" == "yes" ]]; then
      log::info "Figuring out your commit message.."
      msg_proposal="$(lib::exec mktemp)"
      trap "lib::exec rm -f \"$msg_proposal\"" EXIT
      # Send staged diff to AI tool to generate a commit message, then allow user to edit it.
      lib::exec git diff --staged | lib::exec "$SCRIPT_DIR/../../ai-tools/fabric/fabric.sh" -p devops_gitcommit > "$msg_proposal" || true
      lib::exec vim "$msg_proposal"
      msg="$(lib::exec cat "$msg_proposal")"
      if [[ -z "$msg" ]]; then
        log::error "Please provide commit message"
        exit 2
      fi
    else
      # Attempt to convert current branch name into a reasonable commit message and prefill the editor.
      branch_name="$(lib::exec git rev-parse --abbrev-ref HEAD)"
      # Transform branch name:
      # - remove remote prefixes and take the last path segment
      # - strip leading numeric issue ids like "123-" or "123_"
      # - replace dashes/underscores with spaces
      branch_msg="$(echo "$branch_name" | lib::exec sed -E 's#^.*/##; s#^[0-9]+[-_]*##; s#[-_]+# #g')"
      # If branch contains keywords like feat/ or fix/, derive a conventional prefix
      if echo "$branch_name" | lib::exec grep -qE '(^|/)(feat|feature)/'; then
        branch_msg="feat: $branch_msg"
      elif echo "$branch_name" | lib::exec grep -qE '(^|/)(fix|bug|bugfix)/'; then
        branch_msg="fix: $branch_msg"
      fi

      log::info "Please enter your commit message.. (prefilled from branch: $branch_name)"
      msg_proposal="$(lib::exec mktemp)"
      lib::exec trap "lib::exec rm -f \"$msg_proposal\"" EXIT
      lib::exec printf "%s\n" "$branch_msg" > "$msg_proposal"
      lib::exec vim "$msg_proposal"
      msg="$(lib::exec cat "$msg_proposal")"
      if [[ -z "$msg" ]]; then
        log::error "Please provide commit message"
        exit 2
      fi
    fi
  fi

  if [[ ! "$msg" =~ ^(fix:|feat:|docs:|chore:) ]]; then
    # if fix is first word in message, use it as semantic commit prefix
    if [[ "$msg" =~ ^(fix) ]]; then
      msg="fix:${msg#fix*}"
    else
      prefix_choices="fix\nfeat\ndocs\nchore"
      prefix="$(echo -e "$prefix_choices" | lib::exec fzf)"
      if [[ -n "$prefix" ]]; then
        msg="$prefix: $msg"
      fi
    fi
  fi

  if [[ -z "$mr" ]]; then
    mr="$(echo -e "no\nyes" | lib::exec fzf --header "MR")"
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
