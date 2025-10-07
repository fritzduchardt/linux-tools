#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  echo """
Usage: $0 <action> -s <secret_name> -k <secret_key> [-p <secret_path>]

  <action>           Action to perform: remove (required)
  -s <secret_name>   Name of the secret to process
  -k <secret_key>    Key of the secret value to process
  -p <secret_path>   Path to the secret in Vault (default: secret)

Examples:
  $0 remove -s my-secret -k password
  $0 remove -s my-secret -k username -p secret/data
"""
  exit 1
}

remove_key_from_secret() {
  local path="$1"
  local secret_name="$2"
  local secret_key="$3"
  
  local full_path="$path/$secret_name"
  log::info "Processing secret at '$full_path'"
  
  # Get current secret data
  local secret_json
  secret_json="$(lib::exec vault kv get -format=json "$full_path" 2>/dev/null)" || return 1
  
  # Check if key exists
  if ! lib::exec jq -e ".data.data | has(\"$secret_key\")" <<< "$secret_json" >/dev/null 2>&1; then
    log::warn "Key '$secret_key' not found in secret '$full_path'"
    return 1
  fi
  
  # Get remaining keys after removal
  local remaining_data
  remaining_data="$(lib::exec jq -c ".data.data | del(.\"$secret_key\")" <<< "$secret_json")"
  
  if [[ "$remaining_data" == "{}" ]]; then
    log::info "No keys remaining, deleting secret '$full_path'"
    lib::exec vault kv metadata delete "$full_path" || true
    return 0
  fi
  
  # Write back remaining data
  log::info "Updating secret '$full_path' without key '$secret_key'"
  lib::exec vault kv put "$full_path" - <<< "$remaining_data" || true
  return 0
}

search_and_process() {
  local action="$1"
  local path="$2"
  local secret_name="$3"
  local secret_key="$4"
  local found=false
  
  log::debug "Searching in path '$path'"
  
  # List all secrets at current path
  local list_output
  list_output="$(lib::exec vault kv list -format=json "$path" 2>/dev/null)" || return 0
  
  local items
  items="$(lib::exec jq -r '.[]' <<< "$list_output" 2>/dev/null)" || return 0
  
  local item
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    
    if [[ "$item" == */ ]]; then
      # Directory, recurse
      local subpath="${path}/${item%/}"
      search_and_process "$action" "$subpath" "$secret_name" "$secret_key" && found=true
    elif [[ "$item" == "$secret_name" ]]; then
      # Found matching secret name
      if [[ "$action" == "remove" ]]; then
        remove_key_from_secret "$path" "$secret_name" "$secret_key" && found=true
      fi
    fi
  done <<< "$items"
  
  [[ "$found" == true ]] && return 0 || return 1
}

main() {
  local action=""
  local secret_name=""
  local secret_key=""
  local secret_path=""
  
  # Check if first argument is the action
  if [[ $# -gt 0 ]] && [[ "$1" != -* ]]; then
    action="$1"
    shift
  fi
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--secret-name)
        secret_name="$2"
        shift 2
        ;;
      -k|--secret-key)
        secret_key="$2"
        shift 2
        ;;
      -p|--secret-path)
        secret_path="$2"
        shift 2
        ;;
      -h|--help)
        usage
        ;;
      *)
        usage
        ;;
    esac
  done
  
  secret_path="${secret_path:-secret}"
  
  if [[ -z "$action" ]] || [[ -z "$secret_name" ]] || [[ -z "$secret_key" ]]; then
    usage
  fi
  
  if [[ "$action" != "remove" ]]; then
    log::error "Invalid action: '$action'. Only 'remove' is supported."
    usage
  fi
  
  log::info "Action: '$action' - key '$secret_key' from secret '$secret_name' under path '$secret_path'"
  
  if search_and_process "$action" "$secret_path" "$secret_name" "$secret_key"; then
    log::info "Successfully processed secret(s)"
  else
    log::error "No matching secrets found or unable to process"
    exit 1
  fi
}

main "$@"
