#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

RESULT_FOUND=false

usage() {
  echo "Usage: $(lib::exec basename "$0") -s <secret_name> -k <secret_key> [-p <secret_path>]" >&2
  echo
  echo "  -s <secret_name>   Name of the secret to remove"
  echo "  -k <secret_key>    Key of the secret value to remove"
  echo "  -p <secret_path>   Path to the secret in Vault (default: secret)"
  echo
  echo "Examples:"
  echo "  $(lib::exec basename "$0") -s my-secret -k password"
  echo "  $(lib::exec basename "$0") -s my-secret -k username -p secret/data"
  exit 1
}

traverse_kv() {
  local path="$1"
  local secret_name="$2"
  local secret_key="$3"

  log::debug "Traversing path '$path' for secret '$secret_name' key '$secret_key'"

  # attempt to list keys at this path; non-zero listing is tolerated
  local list_json
  list_json="$(lib::exec vault kv list -format=json "$path" 2>/dev/null || true)"

  if [[ -z "$list_json" ]]; then
    log::debug "No listable keys at path '$path'"
    return 1
  fi

  # iterate keys returned by jq
  local key
  local keys
  keys="$(lib::exec jq -r '.[]' <<< "$list_json" 2>/dev/null || true)"

  while IFS= read -r key; do
    if [[ -z "$key" ]]; then
      continue
    fi

    if [[ "$key" == */ ]]; then
      local trimmed_key="${key%/}"
      local next_path="${path%/}/$trimmed_key"
      traverse_kv "$next_path" "$secret_name" "$secret_key"
      # continue even if found to allow searching entire storage; update RESULT_FOUND accordingly
      continue
    fi

    if [[ "$key" == "$secret_name" ]]; then
      log::info "Found secret candidate '$key' at path '$path'"

      # check that the secret exists and capture its JSON; use conditional to avoid set -e exit
      local secret_json
      if secret_json="$(lib::exec vault kv get -format=json "$path/$key" 2>/dev/null || true)"; then
        if [[ -z "$secret_json" ]]; then
          log::warn "Unable to retrieve secret '$key' at path '$path'"
          continue
        fi

        # check whether the requested key exists in the secret data
        if lib::exec jq -e ".data.data | has(\"$secret_key\")" <<< "$secret_json" >/dev/null 2>&1; then
          log::info "Key '$secret_key' exists in secret '$key' at path '$path'"

          # Attempt to remove the key by setting it to an empty string (kv patch accepts key=value).
          # This clears the value for the named key. Some KV backends may not support true deletion
          # of a single key; setting to empty is a safe, CLI-compatible operation.
          if lib::exec vault kv patch "$path/$key" "$secret_key"=""; then
            log::info "Cleared key '$secret_key' in secret '$key' at path '$path'"
            RESULT_FOUND=true
          else
            log::warn "Failed to clear key '$secret_key' in secret '$key' at path '$path'"
          fi
        else
          log::warn "Secret '$key' at path '$path' does not contain key '$secret_key'"
        fi
      else
        log::warn "vault kv get failed for '$path/$key'"
      fi
    fi
  done <<< "$keys"
}

remove_secret() {
  local secret_name="$1" secret_key="$2" secret_path="${3:-secret}"

  log::info "Starting removal search for secret name '$secret_name' and key '$secret_key' under path '$secret_path'"

  traverse_kv "$secret_path" "$secret_name" "$secret_key"

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

  remove_secret "$secret_name" "$secret_key" "$secret_path"
}

main "$@"
