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
alias "ai-setup"="fabric --setup"
alias {ai}="lib::exec_linux_tool $script_dir/fabric fabric.sh"
alias {aiq,ai-question}="lib::exec_linux_tool $script_dir/fabric fabric.sh -p devops_question"
alias {aicmd,ai-cmd}="lib::exec_linux_tool $script_dir/fabric fabric.sh -x -p devops_cmd"
alias {ais,ai-script}="lib::exec_linux_tool $script_dir/fabric fabric.sh -p devops_script"
alias {aia,ai-amend}="lib::exec_linux_tool $script_dir/fabric fabric.sh -p devops_amend -o "
alias {aiac,ai-amend-continue}="lib::exec_linux_tool $script_dir/fabric fabric.sh -p devops_amend -o -c"
alias {aic,ai-chat}="lib::exec_linux_tool $script_dir/fabric fabric_chat.sh"
alias {aib,ai-build}="lib::exec_linux_tool $script_dir/fabric fabric_build.sh"
alias {aistdin,ai-stdin}="lib::exec_linux_tool $script_dir/fabric fabric_stdin.sh"
alias {aigit,ai-git}="lib::exec_linux_tool $script_dir/fabric fabric_stdin.sh -p devops_gitcommit -x"
alias {aidoc,ai-doc}="lib::exec_linux_tool $script_dir/fabric fabric_stdin.sh -p devops_document -x"
alias {aii,ai-improve}="lib::exec_linux_tool $script_dir/fabric fabric_improve.sh"
alias {aiic,ai-improve-continue}="lib::exec_linux_tool $script_dir/fabric fabric_improve.sh -c"
function concat_for_fabric() {
  local file
  for file in "$1"/*; do
    if [[ -d "$file" ]]; then
      echo -e "\n=== $file ===\n";
      echo "Directory"
    else
      echo -e "\n=== $file ===\n";
      cat "$file";
      fi
  done
}
function find_for_fabric() {
  local dir="${1:-.}"
  find "$dir" -type f -not -path '*/.*' | grep -v ".*.txt$"
}
function internet_for_fabric() {
  local url="$1"
  curl -s "$url" | lynx -dump -stdin
}
alias fff="find_for_fabric"
alias cff="concat_for_fabric"
alias iff="internet_for_fabric"
alias {model-ollama,mo}="export DEFAULT_MODEL=qwen2.5-coder:14b DEFAULT_VENDOR=Ollama"
alias {model-claude,mc}="export DEFAULT_MODEL=claude-3-5-sonnet-latest DEFAULT_VENDOR=Anthropic"
alias {model-chatgpt,mg}="export DEFAULT_MODEL=gpt-4o-2024-11-20 DEFAULT_VENDOR=OpenAI"
alias model="env | grep DEFAULT_MODEL"

# misc
alias calc="lib::exec_linux_tool $script_dir/misc calc.sh"
alias tax="lib::exec_linux_tool $script_dir/misc tax.sh calc"
alias help="lib::exec_linux_tool $script_dir/misc help.sh"
