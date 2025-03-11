#!/usr/bin/env bash
SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/fabric_lib.sh"

FABRIC_HOME="/home/fritz/.config/fabric/patterns"
FBRC_BIN="/usr/local/bin/fabric"

# fbrc devops_question what is bash
function fbrc() {
  local pattern session prompt
  if [[ "$#" == "0" ]]; then
    # shellcheck disable=SC2012
    pattern="$(ls "$FABRIC_HOME" | fzf --query=devops_question)"
    log::debug "Pattern: $pattern"
    session="$(fabric --listsessions | fzf --print-query --bind "f2:execute($FBRC_BIN --wipesession {})" | tr -d "\n")"
    log::debug "Session: $session"
    read -r -p "Prompt: " prompt
    prompt="The topic is $session. $prompt"
    log::debug "Prompt: $prompt"
  else
    pattern="$1"
    shift
  fi
  local option="$1" inputfile overwrite output
  if [[ "$option" == "-i" ]]; then
    inputfile="$2"
    shift 2
  fi
  option="$1"
  if [[ "$option" == "-o" ]]; then
    overwrite="true"
    shift
  fi
  local -a fabric_cmd=(fabric --pattern "$pattern")
  if [[ "$option" == "-s" ]]; then
    session="$2"
    shift 2
  fi
  if [[ -n "$session" ]]; then
    fabric_cmd+=(--session "$session")
  fi
  if [[ -z "$prompt" ]]; then
    prompt="$*"
  fi
  # overwrite input file, e.g. to improve existing scripts
  if [[ "$overwrite" == "true" && -n "$inputfile" ]]; then
     output="$("${fabric_cmd[@]}" < "$inputfile" | "${OUTPUT_FILTER[@]}")"
     echo "$output" > "$inputfile"
  # run fabric based on input file and write to stdout and clipboard
  elif [[ -n "$inputfile" ]]; then
    output="$("${fabric_cmd[@]}" < "$inputfile" | "${OUTPUT_FILTER[@]}")"
    echo "$output" | "${XCLIP_COPY[@]}" && "${XCLIP_PASTE[@]}"; echo
  # run fabric based on prompt and write to stdout and clipboard
  else
    output="$("${fabric_cmd[@]}" <<<"$prompt" | "${OUTPUT_FILTER[@]}")"
    echo "$output" | "${XCLIP_COPY[@]}" && "${XCLIP_PASTE[@]}"; echo
  fi
  # write command to zsh history
  echo ": $(date +%s);0;${fabric_cmd[*]}" >> ~/.zsh_history
}

fbrc "$@"
