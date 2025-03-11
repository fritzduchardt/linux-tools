#!/usr/bin/env bash
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
}

function fbrc() {
  local pattern session prompt inputfile overwrite input output copy_to_clipboard

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
      -c)
        copy_to_clipboard=true
        shift
        ;;
      -p)
        pattern="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  [[ -z "$pattern" ]] && pattern="$(ls "$FABRIC_HOME" | fzf --query=devops_question)"
  [[ -z "$session" ]] && session="$(fabric --listsessions | fzf --print-query --bind "f2:execute($FBRC_BIN --wipesession {})" | tr -d "\n")"
  if [[ "$#" == 0 ]]; then
    read -r -p "Prompt: " prompt
    prompt="The topic is $session. $prompt"
    log::debug "Prompt: $prompt"
  fi

  local -a fabric_cmd=(fabric --pattern "$pattern")
  [[ -n "$session" ]] && fabric_cmd+=(--session "$session")
  [[ -z "$prompt" ]] && prompt="$*"

  if [[ "$overwrite" == "true" && -n "$inputfile" ]]; then
    output="$("${fabric_cmd[@]}" < "$inputfile" | "${OUTPUT_FILTER[@]}")"
    echo "$output" > "$inputfile"
  elif [[ -n "$inputfile" ]]; then
    input="$(cat "$inputfile")"
    [[ -n "$prompt" ]] && input="$prompt: $input"
    output="$("${fabric_cmd[@]}" <<<"$input" | "${OUTPUT_FILTER[@]}")"
    if [[ "$copy_to_clipboard" == "true" ]]; then
      echo "$output" | "${XCLIP_COPY[@]}" && "${XCLIP_PASTE[@]}"; echo
    else
      echo "$output"
    fi
  else
    output="$("${fabric_cmd[@]}" <<<"$prompt" | "${OUTPUT_FILTER[@]}")"
    if [[ "$copy_to_clipboard" == "true" ]]; then
      echo "$output" | "${XCLIP_COPY[@]}" && "${XCLIP_PASTE[@]}"; echo
    else
      echo "$output"
    fi
  fi

  echo ": $(date +%s);0;${fabric_cmd[*]}" >> ~/.zsh_history
}

fbrc "$@"
