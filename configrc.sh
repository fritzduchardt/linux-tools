#!/usr/bin/env bash

script_dir="$(dirname -- "${BASH_SOURCE[0]:-${0}}")"

lib::exec_linux_tool() {
  local dir="$1" script="$2"
  shift 2
  "$dir/$script" "$@"
}

# cert
alias "cert-addchain"="lib::exec_linux_tool $script_dir/cert add_chain.sh"

# git
alias {git-cleanbranches,cb}="lib::exec_linux_tool $script_dir/git clean_branches.sh"
alias {git-cleanallbranches,cab}="lib::exec_linux_tool $script_dir/git clean_all_branches.sh"
alias {git-checkout,co}="lib::exec_linux_tool $script_dir/git checkout.sh"
alias {git-sb,sb}="lib::exec_linux_tool $script_dir/git switch_branch.sh"
alias {git-simplecommit,scm}="lib::exec_linux_tool $script_dir/git simple_commit.sh -p"
alias {git-simplecommit-nomr,scM}="lib::exec_linux_tool $script_dir/git simple_commit.sh -M -p"
alias {git-simplecommit-nopush,scP}="lib::exec_linux_tool $script_dir/git simple_commit.sh -a -M -t fix"
alias {git-simplecommit-stage-all,scA}="lib::exec_linux_tool $script_dir/git simple_commit.sh -a -p -M -t fix"
alias {git-updatebranch,ub}="lib::exec_linux_tool $script_dir/git update_branch.sh"
alias {git-deletebranch,db}="lib::exec_linux_tool $script_dir/git delete_branch.sh"

# misc
alias calc="lib::exec_linux_tool $script_dir/misc calc.sh"
alias tax="lib::exec_linux_tool $script_dir/misc tax.sh calc"
alias help="lib::exec_linux_tool $script_dir/misc help.sh"
alias archive="lib::exec_linux_tool $script_dir/misc obsidian.sh archive"
alias plain="lib::exec_linux_tool $script_dir/misc obsidian.sh plain"
