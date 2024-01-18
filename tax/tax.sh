#!/usr/bin/env bash

tax::calc() {
    local numHours="${1?Please provide number of ours}"
    local rate="${2?Please provide rate}"
    # shellcheck disable=SC2079
    let "amount = $numHours * $rate"
    printf "Amount: %0.2f\n" "$amount"
    lib::add_to_clipboard "$amount"
    tax::calcTotal "$amount"
    tax::calcVat "$amount"
}

tax::calcVat() {
    export LC_NUMERIC="en_US.UTF-8"
    local amount="${1?Please provide amount}"
    # shellcheck disable=SC2079
    let "vat = $amount / 100.0 * 19.0"
    printf "Vat: %0.2f\n" "$vat"
    lib::add_to_clipboard "$vat"
}

tax::calcIncome() {
    export LC_NUMERIC="en_US.UTF-8"
    local total="${1?Please provide amount}"
    # shellcheck disable=SC2079
    let "income = $total * 100.0 / 119.0"
    printf "Total: %0.2f\n" "$income"
    lib::add_to_clipboard "$income"
}

tax::calcTotal() {
    local amount="${1?Please provide amount}"
    # shellcheck disable=SC2079
    let "vat = $amount / 100.0 * 19.0"
    let "total = $vat + $amount"
    printf "Total: %0.2f\n" "$total"
    lib::add_to_clipboard "$total"
}

lib::add_to_clipboard() {
  local amount="$1"
    printf "%0.2f" "$amount" | tr ',' '.' | xclip -r -sel clipboard
}
