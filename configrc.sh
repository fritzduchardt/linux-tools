#!/usr/bin/env bash

scripts_dir="$(dirname "$0")"

# git
alias {cleanbranches,cb}="(cd $scripts_dir/git && ./clean_branches.sh)"
clean_all_branches() { (cd "$scripts_dir"/git && ./clean_all_branches.sh "$@") }
alias cab="clean_all_branches"
alias {checkout,co}="( cd $scripts_dir/git && ./checkout.sh)"
switch_branch() { (cd "$scripts_dir"/git && ./switch_branch.sh "$@") }
alias sb="switch_branch"

# misc
calc() { (cd "$scripts_dir"/misc && ./calc.sh "$@") }
tax() { (cd "$scripts_dir"/misc && ./tax.sh calc "$@") }
