#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/vault_lib.sh"

usage() {
  echo """
Usage: $0 <action> -s <secret_name> -k <secret_key> [-p <secret_path>] [-v <value>]

  <action>           Action to perform: remove, add, update (required)
  -s <secret_name>   Name of the secret to process
  -k <secret_key>    Key of the secret value to process
  -p <secret_path>   Path to the secret in Vault (default: secret)
  -v <value>         Value to add/update (required for 'add' and 'update' actions)

Examples:
  $0 remove -s my-secret -k password
  $0 remove -s my-secret -k username -p secret/data
  $0 add -s my-secret -k password -v 'mypassword123'
  $0 add -s my-secret -k api_key -v 'abc123' -p secret/data
  $0 update -s my-secret -k password -v 'newpassword456'
  $0 update -s my-secret -k api_key -v 'xyz789' -p secret/data
"""
  exit 1
}

remove_key_from_secret() {
  local path="$1"
  local secret_key="$2"

  log::info "Processing secret at '$path'"

  # Get current secret data
  local secret_json
  secret_json="$(vault::get_json "$path")"

  if [[ -z "$secret_json" ]]; then
    return 1
  fi

  # Check if key exists
  if ! vault::has_key_in_secret "$secret_json" "$secret_key"; then
    log::warn "Key '$secret_key' not found in secret '$path'"
    return 1
  fi

  # Get remaining keys after removal
  local remaining_data
  remaining_data="$(lib::exec jq -c ".data.data | del(.\"$secret_key\")" <<< "$secret_json")"

  if [[ "$remaining_data" == "{}" ]]; then
    log::info "No keys remaining, deleting secret '$path'"
    vault::delete_metadata "$path" || true
    return 0
  fi

  # Write back remaining data
  log::info "Updating secret '$path' without key '$secret_key'"
  lib::exec vault kv put "$path" - <<< "$remaining_data" || true
  return 0
}

add_key_to_secret() {
  local path="$1"
  local secret_key="$2"
  local value="$3"

  log::info "Adding key '$secret_key' to secret at '$path'"

  # Get current secret data if it exists
  local secret_json
  local existing_data="{}"

  secret_json="$(vault::get_json "$path")"

  if [[ -n "$secret_json" ]]; then
    existing_data="$(lib::exec jq -c ".data.data" <<< "$secret_json")"

    # Check if key already exists
    if lib::exec jq -e "has(\"$secret_key\")" <<< "$existing_data" >/dev/null 2>&1; then
      log::error "Key '$secret_key' already exists in secret '$path'"
      return 1
    fi
  fi

  # Add the key
  local updated_data
  updated_data="$(lib::exec jq -c ". + {\"$secret_key\": \"$value\"}" <<< "$existing_data")"

  # Write the updated data
  log::info "Writing key '$secret_key' to secret '$path'"
  lib::exec vault kv put "$path" - <<< "$updated_data" || true
  return 0
}

update_key_in_secret() {
  local path="$1"
  local secret_key="$2"
  local value="$3"

  log::info "Updating key '$secret_key' in secret at '$path'"

  # Get current secret data
  local secret_json
  secret_json="$(vault::get_json "$path")"

  if [[ -z "$secret_json" ]]; then
    log::error "Secret '$path' does not exist"
    return 1
  fi

  # Check if key exists
  if ! vault::has_key_in_secret "$secret_json" "$secret_key"; then
    log::error "Key '$secret_key' not found in secret '$path'"
    return 1
  fi

  # Get existing data and update the key
  local existing_data
  existing_data="$(lib::exec jq -c ".data.data" <<< "$secret_json")"

  local updated_data
  updated_data="$(lib::exec jq -c ".\"$secret_key\" = \"$value\"" <<< "$existing_data")"

  # Write the updated data
  log::info "Updating key '$secret_key' in secret '$path'"
  lib::exec vault kv put "$path" - <<< "$updated_data" || true
  return 0
}

search_and_process() {
  local action="$1"
  local path="$2"
  local secret_name="$3"
  local secret_key="$4"
  local value="$5"
  local found=false

  log::debug "Searching in path '$path'"

  # List all secrets at current path prefix
  local items
  local base="${path%/*}"
  local prefix="${path##*/}"
  items="$(vault::list_keys "$base" "$prefix")"

  if [[ -z "$items" ]]; then
    return 0
  fi

  local item
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue

    if [[ "$item" == */ ]]; then
      # Directory, recurse
      log::debug "Iterating with $item"
      search_and_process "$action" "$base/$item" "$secret_name" "$secret_key" \
        "$value" && found=true
    elif [[ "$item" == "$secret_name" ]]; then
      log::debug "Found secret"
      # Found matching secret name
      if [[ "$action" == "remove" ]]; then
        remove_key_from_secret "$base/$item" "$secret_key" \
          && found=true
      elif [[ "$action" == "add" ]]; then
        add_key_to_secret "$base/$item" "$secret_key" "$value" \
          && found=true
      elif [[ "$action" == "update" ]]; then
        update_key_in_secret "$base/$item" "$secret_key" \
          "$value" && found=true
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
  local value=""

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
      -v|--value)
        value="$2"
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

  if [[ "$action" != "remove" ]] && [[ "$action" != "add" ]] && [[ "$action" != "update" ]]; then
    log::error "Invalid action: '$action'. Only 'remove', 'add', or 'update' are supported."
    usage
  fi

  if [[ "$action" == "add" ]] || [[ "$action" == "update" ]]; then
    if [[ -z "$value" ]]; then
      log::error "Value is required for '$action' action"
      usage
    fi
  fi

  log::info "Action: '$action' - key '$secret_key' for secret '$secret_name' under path '$secret_path'"

  if search_and_process "$action" "$secret_path" "$secret_name" "$secret_key" "$value"; then
    log::info "Successfully processed secret(s)"
  else
    log::error "No matching secrets found or unable to process"
    exit 1
  fi
}

main "$@"
