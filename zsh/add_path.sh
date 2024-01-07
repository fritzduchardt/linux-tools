#!/usr/bin/env bash

shopt -s globstar # enable globbing

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

RC_FILE="${RC_FILE:-"$HOME/.zshrc"}"


help() {
  echo """

Adds a PATH entry to a shell rc file.

Usage:
    $0 PATH_ENTRY DESCRIPTION

    Arguments:
      PATH_ENTRY                   The path entry to add to the shell rc file
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

add_path_entry() {
  local path_entry="$1"
  local description="$2"
  if ! grep -q 'PATH=$PATH:'"$path_entry" "$RC_FILE"; then
    if [[ -n "$description" ]]; then
      lib::exec echo '# '"$description" >>"$RC_FILE"
    fi
    lib::exec echo 'PATH=$PATH:'"$path_entry" >>"$RC_FILE"
    log::info "Successfully added: $path_entry to $RC_FILE"
    tail "$RC_FILE"
    return 0
  else
    log::warn "Path entry $path_entry already exists in $RC_FILE"
    return 1
  fi
}

main() {

  local path_entry description

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
      if [[ -z "$path_entry" ]]; then
        path_entry="$1"
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
    if [[ -z "$path_entry" ]]; then
      log::error "You must specify a path entry"
      help >&2
      exit 2
    fi
    if [[ ! -d "$path_entry" ]]; then
      log::error "Path entry does not exist on file system: $path_entry"
      exit 2
    fi
    if [[ -z "$RC_FILE" ]]; then
      log::error "Rc file not found: $RC_FILE"
      exit 2
    fi
  }

  add_path_entry "$path_entry" "$description"
}

main "$@"
