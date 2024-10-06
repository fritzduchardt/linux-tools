#!/usr/bin/env bash

script_dir="$(dirname "$0")"

lib::exec_linux_tool() {
  local dir="$1" script="$2"
  shift 2
  "$dir/$script" "$@"
}

# git
alias {cleanbranches,cb}="lib::exec_linux_tool $script_dir/git clean_branches.sh"
alias {cleanallbranches,cab}="lib::exec_linux_tool $script_dir/git clean_all_branches.sh"
alias {checkout,co}="lib::exec_linux_tool $script_dir/git checkout.sh"
alias sb="lib::exec_linux_tool $script_dir/git switch_branch.sh"
alias {simplecommit,sc}="lib::exec_linux_tool $script_dir/git simple_commit.sh"

# misc
alias calc="lib::exec_linux_tool $script_dir/misc calc.sh"
alias tax="lib::exec_linux_tool $script_dir/misc tax.sh calc"
