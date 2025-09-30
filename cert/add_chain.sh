#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  local exit_code=${1:-0}
  cat <<'USAGE'
Usage: add_chain.sh [-c CHAIN_FILE] CERT_FILE

Adds the certificate chain from a config file called "chain" (or specified via -c)
to an existing TLS certificate file. The resulting certificate (original cert +
chain) is written next to the original file and suffixed with -with-chain.crt

Examples:
  add_chain.sh /etc/ssl/certs/server.crt
  add_chain.sh -c /etc/ssl/chain.pem /etc/ssl/certs/server.crt
  add_chain.sh -h
USAGE
  exit "$exit_code"
}

append_chain_to_cert() {
  local cert="$1"
  local chain_file="$2"
  local out="${cert%.*}-with-chain.crt"
  local perms

  if [[ ! -r "$cert" ]]; then
    log::error "Certificate file is not readable: $cert"
    return 2
  fi

  if [[ ! -r "$chain_file" ]]; then
    log::error "Chain file is not readable: $chain_file"
    return 3
  fi

  log::info "Creating copy of certificate at $out"
  if ! lib::exec cp -- "$cert" "$out"; then
    log::error "Failed to copy certificate to $out"
    return 4
  fi

  log::info "Appending chain file $chain_file to $out"
  if ! lib::exec printf "\n%s" "$(cat "$chain_file")" >>"$out"; then
    log::error "Failed to append chain to $out"
    return 5
  fi

  if ! perms="$(lib::exec stat -c %a "$cert")"; then
    log::warning "Could not read permissions of $cert, skipping chmod"
  else
    if ! lib::exec chmod "$perms" "$out"; then
      log::warning "Failed to set permissions on $out"
    fi
  fi

  log::info "Successfully wrote certificate with chain to $out"
  return 0
}

main() {
  local chain_file="${CHAIN_FILE:-./chain}"
  local cert_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--chain)
        if [[ -z "$2" ]]; then
          log::error "Option $1 requires an argument."
          usage 2
        fi
        chain_file="$2"
        shift 2
        ;;
      -h|--help)
        usage 0
        ;;
      -*)
        log::error "Invalid option: $1"
        usage 2
        ;;
      *)
        cert_file="$1"
        shift
        if [[ $# -gt 0 ]]; then
          log::warning "Ignoring extra arguments: $*"
        fi
        break
        ;;
    esac
  done

  if [[ -z "$cert_file" ]]; then
    log::error "No certificate file provided"
    usage 2
  fi

  if [[ ! -f "$chain_file" ]]; then
    log::error "Chain config file not found: $chain_file"
    return 6
  fi

  log::debug "Using chain file: $chain_file"
  log::debug "Target certificate: $cert_file"

  append_chain_to_cert "$cert_file" "$chain_file"
  return $?
}

log::info "Starting add_chain.sh"
main "$@"
rc=$?
exit $rc
