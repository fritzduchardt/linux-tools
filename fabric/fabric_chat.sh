#!/usr/bin/env bash
SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/fabric_lib.sh"

# fbrc devops_question what is bash
function fbrc_chat() {
  local last_cmd prompt output

  last_cmd="$(last_fabric)"
  if [[ "$#" == "0" ]]; then
    read -r -p "Prompt: " prompt
  else
    prompt="$*"
  fi
  # shellcheck disable=SC2086
  output="$(lib::exec $last_cmd <<<"$prompt" | "${OUTPUT_FILTER[@]}")"

  echo "$output" | "${XCLIP_COPY[@]}" && "${XCLIP_PASTE[@]}"; echo
}

fbrc_chat "$@"
