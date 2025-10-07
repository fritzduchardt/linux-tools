#!/usr/bin/env bash

vault::list_json() {
  local path="$1"
  # List keys under a path in Vault KV and return raw JSON (or empty string)
  lib::exec vault kv list -format=json "$path" 2>/dev/null || true
}

vault::list_keys() {
  local path="$1"
  local list_json
  list_json="$(vault::list_json "$path")"
  if [[ -z "$list_json" ]]; then
    echo ""
    return 0
  fi
  # Extract newline-separated keys from JSON array
  lib::exec jq -r '.[]' <<< "$list_json" 2>/dev/null || true
}

vault::get_json() {
  local full_path="$1"
  # Retrieve the secret at full_path as JSON (or empty string)
  lib::exec vault kv get -format=json "$full_path" 2>/dev/null || true
}

vault::has_key_in_secret() {
  local secret_json="$1"
  local key="$2"
  # Check if .data.data has the given key; rely on jq exit code
  if lib::exec jq -e ".data.data | has(\"$key\")" <<< "$secret_json" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

vault::remaining_entries_b64() {
  local secret_json="$1"
  local remove_key="$2"
  # Return base64-encoded entries after deleting a key from the secret's data
  lib::exec jq -r ".data.data | del(.\"$remove_key\") | to_entries[] | @base64" <<< "$secret_json" 2>/dev/null || true
}

vault::decode_b64_to_json() {
  local b64="$1"
  # Decode a base64-encoded jq entry into a JSON string
  lib::exec base64 -d <<< "$b64" 2>/dev/null || true
}

vault::delete_metadata() {
  local full_path="$1"
  # Delete metadata and all versions for a KV secret; return success/failure
  if lib::exec vault kv metadata delete "$full_path"; then
    return 0
  fi
  return 1
}
