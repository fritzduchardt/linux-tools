#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  echo "Usage: $(basename "$0") -s <secret_name> -k <secret_key> [-p <secret_path>]" >&2
  echo
  echo "  -s <secret_name>   Name of the secret to remove"
  echo "  -k <secret_key>    Key of the secret value to remove"
  echo "  -p <secret_path>   Path to the secret in Vault (default: secret)"
  echo
  echo "Examples:"
  echo "  $(basename "$0") -s my-secret -k password"
  echo "  $(basename "$0") -s my-secret -k username -p secret/data"
  exit 1
}

remove_secret() {
  local secret_name="$1"
  local secret_key="$2"
  local secret_path="${3:-secret}"

  log::info "Removing secret '$secret_name' with key '$secret_key' from path '$secret_path'"

  local secrets
  secrets="$(lib::exec vault kv list -format=json "$secret_path")"

  local secret_found=false
  for secret in $(echo "$secrets" | jq -r '.[]'); do
    if [[ "$secret" == "$secret_name" ]]; then
      secret_found=true
      lib::exec vault kv get -format=json "$secret_path/$secret_name" >/dev/null
      if [[ $? -eq 0 ]]; then
        log::info "Secret '$secret_name' found in path '$secret_path'"
        log::info "Removing key '$secret_key' from secret '$secret_name'"
#        lib::exec vault kv patch "$secret_path/$secret_name" "-" <<EOF
#{
#  "$secret_key": null
#}
#EOF
      else
        log::warning "Secret '$secret_name' does not contain key '$secret_key'"
      fi
      break
    fi
  done

  if [[ "$secret_found" == false ]]; then
    log::error "Secret '$secret_name' not found in path '$secret_path'"
    return 1
  fi
}

main() {
  local secret_name secret_key secret_path

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
      *)
        usage
        ;;
    esac
  done

  if [[ -z "$secret_name" ]] || [[ -z "$secret_key" ]]; then
    usage
  fi

  remove_secret "$secret_name" "$secret_key" "$secret_path"
}

main "$@"
