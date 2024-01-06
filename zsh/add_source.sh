#!/usr/bin/env bash

shopt -s globstar # enable globbing

ROOT="${ROOT:-"$(git rev-parse --show-toplevel)"}"

RC_FILE="${RC_FILE:-"$HOME/.zshrc"}"

# shellcheck disable=SC1091
source "$ROOT/lib/log.sh"
# shellcheck disable=SC1091
source "$ROOT/lib/utils.sh"

help() {
  echo """

Adds source file entry to a shell rc file.

Usage:
    $0 SOURCE_FILE DESCRIPTION

    Arguments:
      SOURCE_FILE                  The source file to add to the shell rc file
      DESCRIPTION                  Optional description to add to the shell rc file

    Options:
        -h, --help                  Show this help message
        -D, --debug                 Enable debug logging
        -T, --trace                 Enable trace logging
        -d, --dry-run               Execute in dry-run. Just show commands, don't execute them

    Environment
        RC_FILE                     Path to shell rc file to add path to. Default: $RC_FILE
"""
}

add_source_file() {
  local source_file="$1"
    local description="$2"
  if ! grep -q "source $source_file" "$RC_FILE"; then
    if [[ -n "$description" ]]; then
      lib::exec echo '# '"$description" >>"$RC_FILE"
    fi
    lib::exec echo "source $source_file" >>"$RC_FILE"
    log::info "Successfully added: $source_file to $RC_FILE"
    tail "$RC_FILE"
  else
    log::warn "File $source_file already sourced in $RC_FILE"
  fi
}

main() {

  local source_file description

  # Parse user input
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --help | -h)
      help
      exit 0
      ;;
    --debug | -D)
      # shellcheck disable=SC2034
      LOG_LEVEL=debug
      shift 1
      ;;
    --trace | -T)
      # shellcheck disable=SC2034
      LOG_LEVEL=trace
      shift 1
      ;;
    --dry-run | -d)
      # shellcheck disable=SC2034
      DRY_RUN=true
      shift 1
      ;;
    *)
      if [[ -z "$source_file" ]]; then
        source_file="$1"
        shift 1
      elif [[ -z "$description" ]]; then
        description="$1"
        shift 1
      fi
      ;;
    esac
  done

  # Validate
  {
    if [[ -z "$source_file" ]]; then
      log::error "You must specify a source file"
      help >&2
      exit 2
    fi
    if [[ ! -e "$source_file" ]]; then
      log::error "File $source_file does not exist"
      help >&2
      exit 2
    fi
    if [[ -z "$RC_FILE" ]]; then
      log::error "Rc file not found: $RC_FILE"
      exit 2
    fi
  }

  add_source_file "$source_file" "$description"
}

main "$@"
