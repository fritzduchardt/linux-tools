#!/usr/bin/env bash

# Execute any binary
lib::exec() {
    local command="$1"
    shift
    if [[ -z "$DRY_RUN" ]] || [[ "$DRY_RUN" != "true" ]]; then
        log::trace "$command ${*}"
        "$command" "${@}"
    else
        log::info "DRY-RUN: $command ${*}"
    fi
}

lib::prompt() {
    local msg="${1:-Are your sure?}"
    log::warn "$msg"
    select yn in "yes" "no"; do
        if [[ "$yn" == "no" ]]; then
            log::info "Aborting - good bye."
            exit 0
        else
            break
        fi
    done
}
