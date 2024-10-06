#!/usr/bin/env bash

script_dir="$(dirname "$0")"

lib::exec_function() {
  local dir="$1" script="$2"
  shift 2
  (cd "$dir" && ./"$script" "$@")
}

# git
alias {cleanbranches,cb}="lib::exec_function $script_dir/git clean_branches.sh"
alias {cleanallbranches,cab}="lib::exec_function $script_dir/git clean_all_branches.sh"
alias {checkout,co}="lib::exec_function $script_dir/git checkout.sh"
alias {switch,sb}="lib::exec_function $script_dir/git switch_branch.sh"

# misc
alias calc="lib::exec_function $script_dir/misc calc.sh"
alias tax="lib::exec_function $script_dir/misc tax.sh calc"
