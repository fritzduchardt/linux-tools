#!/usr/bin/env bash
SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/fabric_lib.sh"

# fbrc devops_question what is bash
function fbrc_chat() {
  local last_cmd prompt output

  last_cmd="$(grep -o -E "fabric --pattern \w+ .*" ~/.zsh_history | tac | head -n1)"
  if [[ "$#" == "0" ]]; then
    read -r -p "Prompt: " prompt
    prompt="The topic is $session. $prompt"
  else
    prompt="$*"
  fi
  output="$($last_cmd <<<"$prompt" | "${OUTPUT_FILTER[@]}")"

  echo "$output" | "${XCLIP_COPY[@]}" && "${XCLIP_PASTE[@]}"; echo
}

fbrc_chat "$@"
