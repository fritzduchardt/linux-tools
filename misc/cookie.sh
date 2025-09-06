#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

generate_cookie_secret() {
    local bytes secret
    bytes="${1:-16}"
    secret="$(openssl rand -hex "$bytes")"
    printf '%s' "$secret"
}

main() {
    local bytes secret
    bytes="${COOKIE_SECRET_BYTES:=16}"
    secret="$(generate_cookie_secret "$bytes")"
    log::info "Generated ${bytes}-byte cookie secret: $secret"
}

main "$@"
