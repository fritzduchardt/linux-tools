#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/git_lib.sh"

msg="$*"
if [[ -z "$msg" ]]; then
  log::error "Please provide commit message"
  exit 1
fi
prefix="$(echo -e "fix\nfeat\ndocs" | fzf)"
mr="$(echo -e "no\nyes" | fzf --header "MR")"
force="$(echo -e "no\nyes" | fzf --header "force")"

lib::exec git add .
lib::exec git commit -m "$prefix: $msg"
cmd=(git push origin HEAD)
if [[ "$mr" == "yes" ]]; then
  cmd+=(-o merge_request.create)
fi
if [[ "$force" == "yes" ]]; then
  cmd+=(-f)
fi
lib::exec "${cmd[@]}"
