#!/usr/bin/env bash

vault::list_keys() {
  local base="$1"
  local prefix="$2"
  local result
  result="$(lib::exec vault kv list -format=json "$base" || true)"
  if [[ "$base" != "$prefix" ]]; then
    lib::exec jq -r --arg prefix "$prefix" '.[] | select(startswith($prefix))' <<< "$result"
    return 0
  fi
  lib::exec jq -r '.[]' <<< "$result"
}

vault::get_json() {
  local full_path="$1"
  lib::exec vault kv get -format=json "$full_path" || true
}

vault::has_key_in_secret() {
  local secret_json="$1"
  local key="$2"
  if lib::exec jq -e --arg key "$key" '.data.data | has($key)' <<< "$secret_json" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

vault::delete_metadata() {
  local full_path="$1"
  if lib::exec vault kv metadata delete "$full_path"; then
    return 0
  fi
  return 1
}
