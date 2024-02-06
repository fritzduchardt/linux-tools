#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

tax::calc() {
    local numHours="${1?Please provide number of ours}"
    local rate="${2?Please provide rate}"
    log::info "Calculating for $numHours hours with rate $rate"
    local income
    income=$(echo "scale=2; $numHours * $rate" | bc -l)
    log::info "Income: $income"
    tax::calcTotal "$income"
    tax::calcVat "$income"
    lib::add_to_clipboard "$income"
}

tax::calcVat() {
    export LC_NUMERIC="en_US.UTF-8"
    local amount="${1?Please provide amount}"
    local vat
    vat=$(echo "scale=2; $amount / 100.0 * 19" | bc -l)
    log::info "Vat: $vat"
    lib::add_to_clipboard "$vat"
}

tax::calcIncome() {
    export LC_NUMERIC="en_US.UTF-8"
    local total="${1?Please provide amount}"
    local income
    income=$(echo "scale=2; $total / 100.0 * 119" | bc -l)
    log::info "Income: $income"
    lib::add_to_clipboard "$income"
}

tax::calcTotal() {
    local amount="${1?Please provide amount}"
    local vat total
    vat=$(lib::exec echo "scale=2; $amount.0 / 100.0 * 19.0" | bc -l)
    total=$(lib::exec echo "scale=2; $vat + $amount" | bc -l)
    log::info "Total: $total"
    lib::add_to_clipboard "$total"
}

lib::add_to_clipboard() {
    lib::exec echo "$1" | tr ',' '.' | xclip -r -sel clipboard
}


main() {
    local cmd="$1"
    local amount="$2"
    local rate="$3"

    eval "tax::$cmd" "$amount" "$rate"
}

main "$@"
