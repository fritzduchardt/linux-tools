#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  log::info "Usage:"
  cat <<'USAGE'
vault-kv-manager.sh - manage Vault KV secrets (create, update, remove)

Options:
  -h, --help            Show this help and exit
  -a, --action ACTION   Action to perform: create | update | remove (default: update)
  -m, --mount MOUNT     KV mount path (default: secret)
  -n, --name NAME       Secret name / path (required)
  -k, --key KEY         Key inside the secret (required for create/update; optional for remove)
  -v, --value VALUE     Value to set for the key (required for create/update)
  -i, --interval SEC    Poll interval in seconds when waiting for existing secret (default: 5)
  -t, --timeout SEC     Timeout in seconds for waiting for existing secret (0 = infinite) (default: 0)

Examples:
  # Create a secret with a key/value immediately
  vault-kv-manager.sh -a create -m secret -n myapp/config -k api_key -v "s3cr3t"

  # Update a key for an existing secret (will wait until secret exists)
  vault-kv-manager.sh -a update -m secret -n myapp/config -k api_key -v "n3wval"

  # Remove a specific key from a secret (will wait until secret exists)
  vault-kv-manager.sh -a remove -m secret -n myapp/config -k api_key

  # Remove an entire secret (will wait until secret exists)
  vault-kv-manager.sh -a remove -m secret -n myapp/config
USAGE
}

check_secret_exists() {
  local mount="$1"; local name="$2"
  lib::exec vault kv get -format=json "$mount/$name" >/dev/null 2>&1
  return $?
}

wait_for_secret() {
  local mount="$1"; local name="$2"; local interval="${3:-5}"; local timeout="${4:-0}"
  local start; local elapsed
  start="$(date +%s)"
  while [[ 1 -eq 1 ]]; do
    check_secret_exists "$mount" "$name"
    if [[ $? -eq 0 ]]; then
      log::info "Secret '$name' found at mount '$mount'"
      return 0
    fi
    if [[ $timeout -gt 0 ]]; then
      elapsed=$(( $(date +%s) - start ))
      if [[ $elapsed -ge $timeout ]]; then
        log::error "Timeout waiting for secret '$name' at mount '$mount' after $timeout seconds"
        return 2
      fi
    fi
    log::debug "Secret '$name' not found at mount '$mount', sleeping $interval seconds"
    lib::exec sleep "$interval"
  done
}

do_create() {
  local mount="$1"; local name="$2"; local key="$3"; local value="$4"
  local put_args=()
  put_args+=("$key=$value")
  lib::exec vault kv put "$mount/$name" "${put_args[@]}"
  if [[ $? -eq 0 ]]; then
    log::info "Created secret '$name' at mount '$mount' with key '$key'"
    return 0
  else
    log::error "Failed to create secret '$name' at mount '$mount'"
    return 1
  fi
}

# Read existing KV data and return as bash array of "key=value" entries
read_secret_entries() {
  local mount="$1"; local name="$2"
  local output; local entries_b64; local line
  output="$(lib::exec vault kv get -format=json "$mount/$name" 2>/dev/null)" || return 1
  # Determine whether kv v2 (data.data) or v1 (data)
  entries_b64="$(printf '%s' "$output" | lib::exec jq -r 'if .data then (if .data.data then .data.data else .data end) | to_entries[] | @base64 else empty end')"
  # Print base64 lines to stdout for caller to parse
  if [[ -z "$entries_b64" ]]; then
    return 0
  fi
  printf '%s\n' "$entries_b64"
  return 0
}

assemble_args_from_entries() {
  local -n _out_arr=$1; local mount="$2"; local name="$3"
  local b64; local kv_json; local k; local v
  _out_arr=()
  while IFS= read -r b64; do
    if [[ -z "$b64" ]]; then
      continue
    fi
    kv_json="$(printf '%s' "$b64" | lib::exec base64 --decode 2>/dev/null)" || continue
    k="$(printf '%s' "$kv_json" | lib::exec jq -r '.key')"
    v="$(printf '%s' "$kv_json" | lib::exec jq -r '.value')"
    _out_arr+=("$k=$v")
  done
}

do_update() {
  local mount="$1"; local name="$2"; local key="$3"; local value="$4"
  local entries_b64; local args=(); local found=0; local tmp_args=()
  entries_b64="$(read_secret_entries "$mount" "$name")" || { log::error "Failed to read existing secret '$name' at mount '$mount'"; return 1; }
  # Build args array from existing entries
  assemble_args_from_entries tmp_args "$mount" "$name"
  args=("${tmp_args[@]}")
  # Replace or add the key
  local idx=0
  while [[ $idx -lt ${#args[@]} ]]; do
    local pair="${args[$idx]}"
    local existing_key="${pair%%=*}"
    if [[ "$existing_key" == "$key" ]]; then
      args[$idx]="$key=$value"
      found=1
      break
    fi
    idx=$(( idx + 1 ))
  done
  if [[ $found -eq 0 ]]; then
    args+=("$key=$value")
  fi
  lib::exec vault kv put "$mount/$name" "${args[@]}"
  if [[ $? -eq 0 ]]; then
    log::info "Updated secret '$name' at mount '$mount' set '$key'"
    return 0
  else
    log::error "Failed to update secret '$name' at mount '$mount'"
    return 1
  fi
}

do_remove_key() {
  local mount="$1"; local name="$2"; local key="$3"
  local tmp_args=(); local args=()
  assemble_args_from_entries tmp_args "$mount" "$name"
  if [[ ${#tmp_args[@]} -eq 0 ]]; then
    log::warning "Secret '$name' at mount '$mount' has no keys"
    return 0
  fi
  local removed=0
  for pair in "${tmp_args[@]}"; do
    local k="${pair%%=*}"
    if [[ "$k" == "$key" ]]; then
      removed=1
      continue
    fi
    args+=("$pair")
  done
  if [[ $removed -eq 0 ]]; then
    log::warning "Key '$key' not found in secret '$name' at mount '$mount'"
    return 0
  fi
  if [[ ${#args[@]} -eq 0 ]]; then
    # No keys left, remove entire secret
    lib::exec vault kv delete "$mount/$name"
    if [[ $? -eq 0 ]]; then
      log::info "Removed key '$key' and deleted secret '$name' at mount '$mount' (no remaining keys)"
      return 0
    else
      log::error "Failed to delete secret '$name' at mount '$mount' after removing key '$key'"
      return 1
    fi
  fi
  lib::exec vault kv put "$mount/$name" "${args[@]}"
  if [[ $? -eq 0 ]]; then
    log::info "Removed key '$key' from secret '$name' at mount '$mount'"
    return 0
  else
    log::error "Failed to update secret '$name' at mount '$mount' after removing key '$key'"
    return 1
  fi
}

do_remove_secret() {
  local mount="$1"; local name="$2"
  lib::exec vault kv delete "$mount/$name"
  if [[ $? -eq 0 ]]; then
    log::info "Deleted secret '$name' at mount '$mount'"
    return 0
  else
    log::error "Failed to delete secret '$name' at mount '$mount'"
    return 1
  fi
}

main() {
  local action="update"; local mount="secret"; local name=""; local key=""; local value=""; local interval=5; local timeout=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -a|--action) action="$2"; shift; shift ;;
      -m|--mount) mount="$2"; shift; shift ;;
      -n|--name) name="$2"; shift; shift ;;
      -k|--key) key="$2"; shift; shift ;;
      -v|--value) value="$2"; shift; shift ;;
      -i|--interval) interval="$2"; shift; shift ;;
      -t|--timeout) timeout="$2"; shift; shift ;;
      *) log::error "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done

  if [[ -z "$name" ]]; then
    log::error "Secret name is required"
    usage
    exit 1
  fi

  if [[ "$action" == "create" ]]; then
    if [[ -z "$key" || -z "$value" ]]; then
      log::error "Key and value are required for create action"
      usage
      exit 1
    fi
    do_create "$mount" "$name" "$key" "$value"
    exit $?
  fi

  # For update/remove we wait for the secret to exist
  wait_for_secret "$mount" "$name" "$interval" "$timeout"
  local wait_rc=$?
  if [[ $wait_rc -ne 0 ]]; then
    exit $wait_rc
  fi

  if [[ "$action" == "update" ]]; then
    if [[ -z "$key" || -z "$value" ]]; then
      log::error "Key and value are required for update action"
      usage
      exit 1
    fi
    do_update "$mount" "$name" "$key" "$value"
    exit $?
  elif [[ "$action" == "remove" ]]; then
    if [[ -n "$key" ]]; then
      do_remove_key "$mount" "$name" "$key"
      exit $?
    else
      do_remove_secret "$mount" "$name"
      exit $?
    fi
  else
    log::error "Unknown action: $action"
    usage
    exit 1
  fi
}

main "$@"
