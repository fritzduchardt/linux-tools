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

Adds an alias to a shell rc file.

Usage:
    $0 ALIAS_NAME ALIAS_COMMAND

    Arguments:
      ALIAS_NAME                      Name of alias to add
      ALIAS_COMMAND                   Alias command to add

    Options:
        -h, --help                  Show this help message
        -D, --debug                 Enable debug logging
        -T, --trace                 Enable trace logging
        -d, --dry-run               Execute in dry-run. Just show commands, don't execute them

    Environment
        RC_FILE                     Path to shell rc file to add alias to. Default: $RC_FILE
"""
}

add_alias() {
  local alias_name="$1"
  local alias_command="$2"
  if ! grep -q "alias $alias_name=" "$RC_FILE"; then
    lib::exec echo "alias $alias_name=\"$alias_command\"" >>"$RC_FILE"
    log::info "Successfully added: $alias_name with command: $alias_command"
    tail "$RC_FILE"
  else
    log::warn "alias $alias_name already exists in $RC_FILE"
  fi
}

main() {

  local alias_name
  local alias_command

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
      if [[ -z "$alias_name" ]]; then
        alias_name="$1"
        shift 1
      elif [[ -z "$alias_command" ]]; then
        alias_command="$1"
        shift 1
      fi
      ;;
    esac
  done

  # Validate
  {
    if [[ -z "$alias_name" ]]; then
      log::error "You must specify an alias name"
      help >&2
      exit 2
    fi

    if [[ -z "$alias_command" ]]; then
      log::error "You must specify an alias command"
      exit 2
    fi

    if [[ -z "$RC_FILE" ]]; then
      log::error "Rc file not found: $RC_FILE"
      exit 2
    fi
  }

  add_alias "$alias_name" "$alias_command"
}

main "$@"
