#!/usr/bin/env bash

set -o pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/fabric_lib.sh"

FABRIC_HOME="/home/fritz/.config/fabric/patterns"
FBRC_BIN="/usr/local/bin/fabric"

function show_help() {
  echo "Usage: fbrc [OPTIONS]"
  echo
  echo "Options:"
  echo "  -i INPUTFILE     Specify an input file."
  echo "  -o               Overwrite the input file with output."
  echo "  -s SESSION       Specify a session."
  echo "  -c               Toggle copy to clipboard (default is enabled)."
  echo "  -h               Show this help message."
  echo "  --continue       Don't reset session."
}

function fbrc() {
  local pattern session prompt inputfile overwrite input output copy_to_clipboard continue

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h)
        show_help
        exit 0
        ;;
      -i)
        inputfile="$2"
        shift 2
        ;;
      -o)
        overwrite="true"
        shift
        ;;
      -s)
        session="$2"
        shift 2
        ;;
      -x)
        copy_to_clipboard=true
        shift
        ;;
      -p)
        pattern="$2"
        shift 2
        ;;
      -c | --continue)
        continue="true"
        shift 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ -z "$pattern" ]]; then
    pattern="$(ls "$FABRIC_HOME" | fzf --query=devops_question)"
  fi
  if [[ -n "$continue" ]]; then
    session="$(last_session)"
  fi
  if [[ -z "$session" ]]; then
    if session="$(fabric --listsessions | fzf --print-query -e --bind "f2:execute($FBRC_BIN --wipesession {})")"; then
      session="$(tail -n1 <<<"$session")"
      lib::exec "$FBRC_BIN" --wipesession "$session"
    fi
  fi
  if [[ "$#" == 0 ]]; then
    read -r -p "Prompt: " prompt
    prompt="The topic is $session. $prompt"
    log::debug "Prompt: $prompt"
  fi

  local -a fabric_cmd=(fabric --stream --pattern "$pattern")
  [[ -n "$session" ]] && fabric_cmd+=(--session "$session")
  [[ -z "$prompt" ]] && prompt="$*"

  echo "${fabric_cmd[*]}" >> ~/.bash_history

  # handle input file
  if [[ -n "$inputfile" ]]; then
    input="$(cat "$inputfile")"
    [[ -n "$prompt" ]] && input="$prompt: $input"
    output="$(lib::exec "${fabric_cmd[@]}" <<<"$input" | "${OUTPUT_FILTER[@]}")"
    if [[ "$overwrite" == "true" ]]; then
      echo "$output" > "$inputfile"
    else
      echo "$output"
    fi
  # handle prompt
  else
    if [[ "$copy_to_clipboard" == "true" ]]; then
      output="$(lib::exec "${fabric_cmd[@]}" <<<"$prompt" | "${OUTPUT_FILTER[@]}")"
      echo "$output" | "${XCLIP_COPY[@]}" && "${XCLIP_PASTE[@]}"; echo
    else
      lib::exec "${fabric_cmd[@]}" <<<"$prompt" | "${OUTPUT_FILTER[@]}"
    fi
  fi

}

fbrc "$@"
