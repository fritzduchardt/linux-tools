#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  log::info "Usage:"
  cat <<'USAGE'
Manage Vault KV secrets (create, update, remove)

Usage:
  $0 -a ACTION -m MOUNT -n NAME [options]

Options:
  -h, --help            Show this help and exit
  -a, --action ACTION   Action to perform: create | update | remove (default: update)
  -m, --mount MOUNT     KV mount path (default: secret)
  -n, --name NAME       Secret name / path (required)
  -k, --key KEY         Key inside the secret (required for create/update; optional for remove)
  -v, --value VALUE     Value to set for the key (required for create/update)

Examples:
  # Create a secret with a key/value immediately
  $0 -a create -m secret -n myapp/config -k api_key -v "s3cr3t"

  # Update a key for an existing secret (attempts update immediately)
  $0 -a update -m secret -n myapp/config -k api_key -v "n3wval"

  # Remove a specific key from a secret (attempts removal immediately)
  $0 -a remove -m secret -n myapp/config -k api_key

  # Remove an entire secret (attempts removal immediately)
  $0 -a remove -m secret -n myapp/config
USAGE
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

# Read existing KV data and return as base64-encoded lines of entries (caller receives via stdout)
read_secret_entries() {
  local mount="$1"; local name="$2"
  local output; local entries_b64
  output="$(lib::exec vault kv get -format=json "$mount/$name" 2>/dev/null)" || return 1
  # Determine whether kv v2 (data.data) or v1 (data) and emit base64-encoded entries
  entries_b64="$(printf '%s' "$output" | lib::exec jq -r 'if .data then (if .data.data then .data.data else .data end) | to_entries[] | @base64 else empty end')"
  if [[ -z "$entries_b64" ]]; then
    return 0
  fi
  printf '%s\n' "$entries_b64"
  return 0
}

assemble_args_from_entries() {
  local -n _out_arr="$1"; local mount="$2"; local name="$3"
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
  local entries_out; local args=(); local found=0; local tmp_args=()
  if ! entries_out="$(read_secret_entries "$mount" "$name")"; then
    log::error "Failed to read existing secret '$name' at mount '$mount'"
    return 1
  fi
  assemble_args_from_entries tmp_args "$mount" "$name" <<<"$entries_out"
  args=("${tmp_args[@]}")
  local idx=0
  while [[ $idx -lt ${#args[@]} ]]; do
    local pair="${args[$idx]}"
    # extract existing key
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
  local entries_out
  if ! entries_out="$(read_secret_entries "$mount" "$name")"; then
    log::error "Failed to read existing secret '$name' at mount '$mount'"
    return 1
  fi
  assemble_args_from_entries tmp_args "$mount" "$name" <<<"$entries_out"
  if [[ ${#tmp_args[@]} -eq 0 ]]; then
    log::warning "Secret '$name' at mount '$mount' has no keys"
    return 0
  fi
  local removed=0
  local pair
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

find_secrets() {
  local mount="$1"; local name="$2"
  local secrets
  secrets="$(lib::exec vault kv list -format=json "$mount")" || return 1
  printf '%s' "$secrets" | lib::exec jq -r --arg name "$name" '.[] | select(startswith($name))'
}

process_secrets() {
  local action="$1"; local mount="$2"; local name="$3"; local key="$4"; local value="$5"
  local secret
  while IFS= read -r secret; do
    case "$action" in
      create) do_create "$mount" "$secret" "$key" "$value" ;;
      update) do_update "$mount" "$secret" "$key" "$value" ;;
      remove) do_remove_key "$mount" "$secret" "$key" ;;
      *) log::error "Unknown action: $action"; return 1 ;;
    esac
  done
}

main() {
  local action="update"; local mount="secret"; local name=""; local key=""; local value=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -a|--action) action="$2"; shift; shift ;;
      -m|--mount) mount="$2"; shift; shift ;;
      -n|--name) name="$2"; shift; shift ;;
      -k|--key) key="$2"; shift; shift ;;
      -v|--value) value="$2"; shift; shift ;;
      *) log::error "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done

  if [[ -z "$name" ]]; then
    log::error "Secret name is required"
    usage
    exit 1
  fi

  if [[ "$action" == "create" || "$action" == "update" ]]; then
    if [[ -z "$key" || -z "$value" ]]; then
      log::error "Key and value are required for create and update actions"
      usage
      exit 1
    fi
  fi

  if [[ "$action" == "remove" && -z "$key" ]]; then
    log::error "Key is required for remove action"
    usage
    exit 1
  fi

  local secrets
  if ! secrets="$(find_secrets "$mount" "$name")"; then
    log::error "Failed to find secrets matching '$name' at mount '$mount'"
    exit 1
  fi

  if [[ -z "$secrets" ]]; then
    log::warning "No secrets found matching '$name' at mount '$mount'"
    exit 0
  fi

  process_secrets "$action" "$mount" "$name" "$key" "$value" <<<"$secrets"
  exit $?
}

main "$@"
