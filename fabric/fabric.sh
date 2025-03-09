#!/usr/bin/env bash

# fbrc devops_question what is bash
function fbrc() {
  local pattern="$1"
  shift
  local option="$1" inputfile overwrite output
  local -a xclip_copy xclip_paste output_filter
  xclip_copy=(xclip -r -sel clip)
  xclip_paste=(xclip -sel clip -o)
  output_filter=(grep -v "Creating new session:")
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
    # shellcheck disable=SC2064
    fabric_cmd+=(--session "$2")
    shift 2
  fi
  # overwrite input file, e.g. to improve existing scripts
  if [[ "$overwrite" == "true" && -n "$inputfile" ]]; then
     output="$("${fabric_cmd[@]}" < "$inputfile" | "${output_filter[@]}")"
     echo "$output" > "$inputfile"
  # run fabric based on input file and write to stdout and clipboard
  elif [[ -n "$inputfile" ]]; then
    output="$("${fabric_cmd[@]}" < "$inputfile" | "${output_filter[@]}")"
    echo "$output" | "${xclip_copy[@]}" && "${xclip_paste[@]}"; echo
  # run fabric based on prompt and write to stdout and clipboard
  else
    output="$("${fabric_cmd[@]}" <<<"$*" | "${output_filter[@]}")"
    echo "$output" | "${xclip_copy[@]}" && "${xclip_paste[@]}"; echo
  fi
}

fbrc "$@"
