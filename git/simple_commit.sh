#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

usage() {
  echo """
Usage: $0 [options] [commit message]

Commit changes with optional AI-generated commit messages

Options:
  -m            Create merge request (yes)
  -M            Don't create merge request (no)
  -f            Force push
  -p            Push after commit
  -a            Stage all files before commit
  -i            Use AI to suggest commit message (only executed when provided)
  -t <type>     Semantic commit type to prefix message with (e.g. feat, fix, docs, chore)
  -h, --help    Display this help message

If no commit message is provided and -i is not passed, you will be prompted to enter one.

Examples:
  $0 -a -p -m "fix: correct typo in README"
  $0 -a -p -i    # use AI to propose a commit message
  $0 -a -p -t feat "add new user onboarding flow"
"""
}

log::warn_to_warning() {
  log::warn "$1"
}

main() {
  local mr=""
  local force=""
  local push=""
  local msg=""
  local ai=""
  local msg_proposal=""
  local prefix_choices=""
  local prefix=""
  local cmd=()
  local main_branch=""
  local current_branch=""
  local all=""
  local branch_name=""
  local branch_msg=""
  local semantic_type=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m) mr="yes"; shift ;;
      -M) mr="no"; shift ;;
      -f) force="yes"; shift ;;
      -p) push="yes"; shift ;;
      -a) all="yes"; shift ;;
      -i) ai="yes"; shift ;;
      -t) semantic_type="$2"; shift 2 ;;
      --type) semantic_type="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
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
      lib::exec git diff --staged | lib::exec "$SCRIPT_DIR/../../ai-tools/fabric/fabric.sh" -p devops_gitcommit > "$msg_proposal" || true
      lib::exec vim "$msg_proposal"
      msg="$(lib::exec cat "$msg_proposal")"
      if [[ -z "$msg" ]]; then
        log::error "Please provide commit message"
        exit 2
      fi
    else
      branch_name="$(lib::exec git rev-parse --abbrev-ref HEAD)"
      branch_msg="$(echo "$branch_name" | lib::exec sed -E 's#^.*/##; s#^[0-9]+[-_]*##; s#[-_]+# #g')"
      if echo "$branch_name" | lib::exec grep -qE '(^|/)(feat|feature)/'; then
        branch_msg="feat: $branch_msg"
      elif echo "$branch_name" | lib::exec grep -qE '(^|/)(fix|bug|bugfix)/'; then
        branch_msg="fix: $branch_msg"
      fi

      log::info "Please enter your commit message.. (prefilled from branch: $branch_name)"
      msg_proposal="$(lib::exec mktemp)"
      trap "lib::exec rm -f \"$msg_proposal\"" EXIT
      lib::exec printf "%s\n" "$branch_msg" > "$msg_proposal"
      lib::exec vim "$msg_proposal"
      msg="$(lib::exec cat "$msg_proposal")"
      if [[ -z "$msg" ]]; then
        log::error "Please provide commit message"
        exit 2
      fi
    fi
  fi

  if [[ -n "$semantic_type" ]]; then
    if ! [[ "$msg" =~ ^($semantic_type:|fix:|feat:|docs:|chore:) ]]; then
      msg="$semantic_type: $msg"
    fi
  else
    if [[ ! "$msg" =~ ^(fix:|feat:|docs:|chore:) ]]; then
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
