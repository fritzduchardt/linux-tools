#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  local exit_code=0
  if [[ $# -gt 0 ]]; then
    exit_code=$1
  fi

  cat <<'USAGE'
Usage: add-cert-chain.sh [-c CHAIN_FILE] CERT_FILE

Adds the certificate chain from a config file called "chain" (or specified via -c)
to an existing TLS certificate file. The resulting certificate (original cert +
chain) is written next to the original file and suffixed with -with-chain.crt

Examples:
  add-cert-chain.sh /etc/ssl/certs/server.crt
  add-cert-chain.sh -c /etc/ssl/chain.pem /etc/ssl/certs/server.crt
  add-cert-chain.sh -h
USAGE

  exit "$exit_code"
}

log::info "Starting add-cert-chain.sh"

append_chain_to_cert() {
  local cert="$1"
  local chain_file="$2"
  local out
  local perms

  out="${cert%.*}-with-chain.crt"

  if [[ ! -r "$cert" ]]; then
    log::error "Certificate file is not readable: $cert"
    return 2
  fi

  if [[ ! -r "$chain_file" ]]; then
    log::error "Chain file is not readable: $chain_file"
    return 3
  fi

  log::info "Creating copy of certificate at $out"
  lib::exec cp -- "$cert" "$out"
  if [[ $? -ne 0 ]]; then
    log::error "Failed to copy certificate to $out"
    return 4
  fi

  log::info "Appending chain file $chain_file to $out"
  # Use tee to append chain file to the copied cert file to avoid relying on shell redirection.
  lib::exec tee -a "$out" < "$chain_file" > /dev/null
  if [[ $? -ne 0 ]]; then
    log::error "Failed to append chain to $out"
    return 5
  fi

  # Preserve original file permissions on the new file.
  perms="$(lib::exec stat -c %a "$cert")"
  if [[ $? -ne 0 ]]; then
    log::warning "Could not read permissions of $cert, skipping chmod"
  else
    lib::exec chmod "$perms" "$out"
    if [[ $? -ne 0 ]]; then
      log::warning "Failed to set permissions on $out"
    fi
  fi

  log::info "Successfully wrote certificate with chain to $out"
  return 0
}

main() {
  local chain_file opt
  chain_file="${chain_file:-./chain}"

  while getopts ":c:h" opt; do
    if [[ "$opt" == "c" ]]; then
      chain_file="$OPTARG"
    elif [[ "$opt" == "h" ]]; then
      usage 0
    else
      usage 2
    fi
  done

  shift $((OPTIND - 1))

  if [[ $# -lt 1 ]]; then
    log::error "No certificate file provided"
    usage 2
  fi

  local cert_file="$1"

  if [[ ! -f "$chain_file" ]]; then
    log::error "Chain config file not found: $chain_file"
    return 6
  fi

  append_chain_to_cert "$cert_file" "$chain_file"
  return $?
}

main "$@"
