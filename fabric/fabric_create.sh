#!/usr/bin/env bash

function fbrc() {
  local pattern="$1"
  shift
  local option="$1" outputfile inputfile overwrite output
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
  if [[ "$overwrite" == "true" && -n "$inputfile" ]]; then
     output="$("${fabric_cmd[@]}" < "$inputfile")"
     echo "$output" > "$inputfile"
  elif [[ -n "$inputfile" ]]; then
     "${fabric_cmd[@]}" < "$inputfile"
  else
    "${fabric_cmd[@]}" <<<"$*"
  fi
}

function fbrcc() {
  local list="$1" dir file desc path
  while IFS= read -r line; do
    path="${line%--*}"
    desc="${line#*-- }"
    file="${path##*/}"
    dir="${path%/*}"
    echo "desc: $desc"
    echo "file: $file"
    echo "dir: $dir"
    mkdir -p "$dir"
    if [[ "$file" != "" ]]; then
      fbrc devops_script "Content of $file: $desc" > "$path"
    fi
  done < "$list"
}

fbrcc "$@"
