#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  cat <<EOF
Usage:
  "$0" <command> [path] [duration]

Commands:
  archive [path] [duration]
      Archive dated entries in markdown files.

Arguments:
  path      Directory to search (default: current directory).
  duration  Time frame to archive:
               Nd  days ago
               Nm  months ago
               Ny  years ago
             (default: 1y)

Examples:
  "$0" archive
  "$0" archive ./notes 1y
EOF
  exit 1
}

cmd_archive() {
  local target_dir="."
  local duration="6m" # Default duration
  local cutoff_ts date_str find_cmd

  # Handle arguments: [path] [duration]
  # The first argument can be a path or a duration if only one is provided.
  if [[ $# -eq 1 ]]; then
    if [[ "$1" =~ ^[0-9]+[dmy]$ ]]; then
      duration="$1"
    else
      target_dir="$1"
    fi
  elif [[ $# -eq 2 ]]; then
    target_dir="$1"
    duration="$2"
  elif [[ $# -gt 2 ]]; then
    usage
  fi

  if [[ ! -d "$target_dir" ]]; then
    log::error "Directory \"$target_dir\" does not exist"
    exit 1
  fi

  case "$duration" in
    *d) date_str="${duration%d} days ago" ;;
    *m) date_str="${duration%m} months ago" ;;
    *y) date_str="${duration%y} years ago" ;;
    *)
      log::error "Invalid duration: \"$duration\""
      exit 1
      ;;
  esac

  cutoff_ts=$(lib::exec date --date="$date_str" +%s)

  # Find all markdown files, excluding any .archive directories
  find_cmd=(find "$target_dir" -type d -name '*.archive' -prune -o -type f -name '*.md' -print)
  while IFS= read -r file; do
    archive_file "$file" "$cutoff_ts"
  done < <(lib::exec "${find_cmd[@]}")
}

archive_file() {
  local file="$1"
  local cutoff_ts="$2"
  local filedir base temp_file in_block=0 modified=0
  local header_date header_ts year month day archive_dir archive_path

  filedir=$(dirname -- "$file")
  base=$(basename -- "$file" .md)
  temp_file=$(mktemp)
  # Ensure temp file is removed on exit, error or interrupt
  trap 'rm -f "$temp_file"' EXIT

  while IFS= read -r line; do
    # Match date headers in format *2023-01-01* or **2023-01-01** or just 2023-01-01
    if [[ "$line" =~ ^\**([0-9]{4})-([0-9]{2})-([0-9]{2})\**$ ]]; then
      year="${BASH_REMATCH[1]}"
      month="${BASH_REMATCH[2]}"
      day="${BASH_REMATCH[3]}"
      header_date="$year-$month-$day"
      header_ts=$(lib::exec date --date="$header_date" +%s)

      if ((header_ts < cutoff_ts)); then
        if [[ $modified -eq 0 ]]; then
          log::info "Archiving entries in: $file"
          modified=1
        fi
        archive_dir="$filedir/$year.archive"
        lib::exec mkdir -p "$archive_dir"
        archive_path="$archive_dir/$base.md"
        echo "$line" >>"$archive_path"
        in_block=1
      else
        echo "$line" >>"$temp_file"
        in_block=0
      fi
    elif [[ $in_block -eq 1 ]]; then
      echo "$line" >>"$archive_path"
    else
      echo "$line" >>"$temp_file"
    fi
  done <"$file"

  if [[ $modified -eq 1 ]]; then
    # Atomically replace the original file with the filtered content
    lib::exec mv "$temp_file" "$file"
    # If the original file is now empty, remove it
    if [[ ! -s "$file" ]]; then
      log::info "Removing empty file: $file"
      lib::exec rm "$file"
    fi
  else
    # No changes were made, just remove the temp file
    rm -f "$temp_file"
  fi

  # Disable the trap on a clean exit from the function
  trap - EXIT
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local command="$1"
  shift

  case "$command" in
    archive)
      cmd_archive "$@"
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
