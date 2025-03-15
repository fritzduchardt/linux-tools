#!/usr/bin/env bash

script_dir="$(dirname -- "${BASH_SOURCE[0]:-${0}}")"

lib::exec_linux_tool() {
  local dir="$1" script="$2"
  shift 2
  "$dir/$script" "$@"
}

# git
alias {git-cleanbranches,cb}="lib::exec_linux_tool $script_dir/git clean_branches.sh"
alias {git-cleanallbranches,cab}="lib::exec_linux_tool $script_dir/git clean_all_branches.sh"
alias {git-checkout,co}="lib::exec_linux_tool $script_dir/git checkout.sh"
alias {git-sb,sb}="lib::exec_linux_tool $script_dir/git switch_branch.sh"
alias {git-simplecommit,scm}="lib::exec_linux_tool $script_dir/git simple_commit.sh"
alias {git-updatebranch,ub}="lib::exec_linux_tool $script_dir/git update_branch.sh"
alias {git-deletebranch,db}="lib::exec_linux_tool $script_dir/git delete_branch.sh"

# fabric
alias {fbrc,ai}="lib::exec_linux_tool $script_dir/fabric fabric.sh"
alias {fbrcq,aiq}="lib::exec_linux_tool $script_dir/fabric fabric.sh -p devops_question"
alias {fbrccmd,aicmd}="lib::exec_linux_tool $script_dir/fabric fabric.sh -c -p devops_cmd"
alias {fbrcs,ais}="lib::exec_linux_tool $script_dir/fabric fabric.sh -p devops_script"
alias {fbrca,aia}="lib::exec_linux_tool $script_dir/fabric fabric.sh -p devops_amend"
alias {fbrcc,aic}="lib::exec_linux_tool $script_dir/fabric fabric_chat.sh"
alias {fbrcb,aib}="lib::exec_linux_tool $script_dir/fabric fabric_build.sh"
alias {fbrci,aii}="lib::exec_linux_tool $script_dir/fabric fabric_improve.sh"
function find_for_fabric() {
  local dir="${1:-.}"
  find "$dir" -type f -not -path '*/.*' | grep -v ".*.txt$"
}
alias fff="find_for_fabric"

# misc
alias calc="lib::exec_linux_tool $script_dir/misc calc.sh"
alias tax="lib::exec_linux_tool $script_dir/misc tax.sh calc"
alias help="lib::exec_linux_tool $script_dir/misc help.sh"
