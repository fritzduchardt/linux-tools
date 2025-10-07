#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/vault_lib.sh"

usage() {
  echo "Usage: $0 -s <secret_name> -k <secret_key> [-p <secret_path>]" >&2
  echo
  echo "  -s <secret_name>   Name of the secret to remove"
  echo "  -k <secret_key>    Key of the secret value to remove"
  echo "  -p <secret_path>   Path to the secret in Vault (default: secret)"
  echo
  echo "Examples:"
  echo "  $0 -s my-secret -k password"
  echo "  $0 -s my-secret -k username -p secret/data"
  exit 1
}

traverse_kv_store_for_secret() {
  local path="$1" secret_name="$2" secret_key="$3"

  log::debug "Traversing path '$path' for secret '$secret_name' key '$secret_key'"

  local list_keys key
  list_keys="$(vault::list_keys "$path")"

  if [[ -z "$list_keys" ]]; then
    log::debug "No listable keys at path '$path'"
    return 1
  fi

  while IFS= read -r key; do
    if [[ -z "$key" ]]; then
      continue
    fi

    if [[ "$key" == */ ]]; then
      local trimmed_key="${key%/}" next_path="${path%/}/$trimmed_key"
      traverse_kv_store_for_secret "$next_path" "$secret_name" "$secret_key"
    elif [[ "$key" == "$secret_name" ]]; then
      log::info "Found secret candidate '$key' at path '$path'"

      local secret_json
      secret_json="$(vault::get_json "$path/$key")"

      if [[ -z "$secret_json" ]]; then
        log::warn "Unable to retrieve secret '$key' at path '$path'"
        continue
      fi

      if vault::has_key_in_secret "$secret_json" "$secret_key"; then
        log::info "Key '$secret_key' exists in secret '$key' at path '$path'"

        local remaining_entries entry_b64 decoded entry_key entry_value
        remaining_entries="$(vault::remaining_entries_b64 "$secret_json" "$secret_key")"

        if [[ -z "$remaining_entries" ]]; then
          log::info "No remaining keys after removing '$secret_key'; deleting metadata for '$key' at path '$path'"
          if vault::delete_metadata "$path/$key"; then
            log::info "Deleted metadata and all versions for secret '$key' at path '$path'"
            RESULT_FOUND=true
          else
            log::warn "Failed to delete metadata for secret '$key' at path '$path'"
          fi
          continue
        fi

        local args=( "vault" "kv" "put" "$path/$key" )

        while IFS= read -r entry_b64; do
          if [[ -z "$entry_b64" ]]; then
            continue
          fi

          decoded="$(vault::decode_b64_to_json "$entry_b64")"

          if [[ -z "$decoded" ]]; then
            log::warn "Failed to decode entry for secret '$key' at path '$path'; skipping entry"
            continue
          fi

          entry_key="$(lib::exec jq -r '.key' <<< "$decoded" 2>/dev/null || true)"
          entry_value="$(lib::exec jq -r '.value' <<< "$decoded" 2>/dev/null || true)"

          if [[ -z "$entry_key" ]]; then
            log::warn "Decoded entry missing key for secret '$key' at path '$path'; skipping"
            continue
          fi

          args+=( "$entry_key=$entry_value" )
        done <<< "$remaining_entries"

        if [[ "${#args[@]}" -gt 3 ]]; then
          if lib::exec "${args[@]}"; then
            log::info "Wrote new version of secret '$key' at path '$path' with '$secret_key' removed"
            RESULT_FOUND=true
          else
            log::warn "Failed to write new version of secret '$key' at path '$path'"
          fi
        else
          log::warn "No valid remaining entries prepared to write for secret '$key' at path '$path'"
        fi
      else
        log::warn "Secret '$key' at path '$path' does not contain key '$secret_key'"
      fi
    fi
  done <<< "$list_keys"
}

remove_secret_key_from_kv_tree() {
  local secret_name="$1" secret_key="$2" secret_path="${3:-secret}"

  log::info "Starting removal search for secret name '$secret_name' and key '$secret_key' under path '$secret_path'"

  traverse_kv_store_for_secret "$secret_path" "$secret_name" "$secret_key"

  if [[ "$RESULT_FOUND" == false ]]; then
    log::error "Secret '$secret_name' with key '$secret_key' not found anywhere under path '$secret_path'"
    return 1
  fi

  log::info "Completed search; changes applied where applicable"
}

main() {
  local secret_name="" secret_key="" secret_path=""

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

  if [[ -z "$secret_name" ]] || [[ -z "$secret_key" ]]; then
    usage
  fi

  RESULT_FOUND=false

  remove_secret_key_from_kv_tree "$secret_name" "$secret_key" "$secret_path"
}

main "$@"
