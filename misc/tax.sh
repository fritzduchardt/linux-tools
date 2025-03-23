#!/usr/bin/env bash

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

export LC_NUMERIC="en_US.UTF-8"
readonly VAT_RATE=19

validate_args() {
    if [[ $# -lt 1 ]]; then
        log::error "Missing command. Usage: $0 <command> [amount] [rate]"
        exit 1
    fi

    local cmd="$1"
    if [[ ! "$cmd" =~ ^(calc|calcVat|calcIncome|calcTotal)$ ]]; then
        log::error "Invalid command: $cmd"
        exit 1
    fi

    if [[ "$cmd" == "calc" && $# -lt 3 ]]; then
        log::error "calc requires both amount and rate"
        exit 1
    elif [[ "$cmd" != "calc" && $# -lt 2 ]]; then
        log::error "$cmd requires amount parameter"
        exit 1
    fi
}

tax::calc() {
    local numHours="${1?Please provide number of hours}"
    local rate="${2?Please provide rate}"
    log::info "Calculating for $numHours hours with rate $rate"
    local income
    income=$(bc -l <<< "scale=2; $numHours * $rate")
    log::info "Income: $income"
    tax::calcTotal "$income"
    tax::calcVat "$income"
    lib::add_to_clipboard "$income"
}

tax::calcVat() {
    local amount="${1?Please provide amount}"
    local vat
    vat=$(bc -l <<< "scale=2; $amount / 100.0 * $VAT_RATE")
    log::info "Vat: $vat"
    lib::add_to_clipboard "$vat"
}

tax::calcIncome() {
    local total="${1?Please provide amount}"
    local income
    income=$(bc -l <<< "scale=2; $total / 100.0 * $(( 100 + VAT_RATE ))")
    log::info "Income: $income"
    lib::add_to_clipboard "$income"
}

tax::calcTotal() {
    local amount="${1?Please provide amount}"
    local vat total
    vat=$(bc -l <<< "scale=2; $amount / 100.0 * $VAT_RATE")
    total=$(bc -l <<< "scale=2; $vat + $amount")
    log::info "Total: $total"
    lib::add_to_clipboard "$total"
}

lib::add_to_clipboard() {
    lib::exec echo "$1" | tr ',' '.' | xclip -r -sel clipboard
}

main() {
    validate_args "$@"
    local cmd="$1"
    local amount="$2"
    local rate="$3"
    tax::"$cmd" "$amount" "$rate"
}

main "$@"
