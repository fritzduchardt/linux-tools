current_dir=$(dirname "$0")
# aliases
# git
alias {cleanbranches,cb}="$current_dir"/git/clean_branches.sh
alias {checkout,co}="$current_dir"/git/checkout.sh

# misc
alias cbm="$current_dir/git/clean_branches.sh master"
alias calc="$current_dir"/misc/calc.sh
alias tax="$current_dir/misc/tax.sh calc"
