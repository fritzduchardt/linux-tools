#!/usr/bin/env bash
set -eo pipefail
SCRIPT_DIR=$(dirname -- "$0")
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
  "$0" archive ./notes 6m
EOF
  exit 1
}

cmd_archive() {
  local target_dir duration cutoff_ts date_str find_cmd
  if [[ $# -gt 2 ]]; then
    usage
  fi

  if [[ $# -eq 1 ]]; then
    if [[ $1 =~ ^[0-9]+[dmy]$ ]]; then
      target_dir="."
      duration="$1"
    else
      target_dir="$1"
      duration="6m"
    fi
  else
    target_dir=${1:-.}
    duration=${2:-6m}
  fi

  if [[ ! -d "$target_dir" ]]; then
    log::error "Directory $target_dir does not exist"
    exit 1
  fi

  case "$duration" in
    *d)
      date_str="${duration%d} days ago"
      ;;
    *m)
      date_str="${duration%m} months ago"
      ;;
    *y)
      date_str="${duration%y} years ago"
      ;;
    *)
      log::error "Invalid duration: $duration"
      exit 1
      ;;
  esac

  cutoff_ts=$(lib::exec date --date="$date_str" +%s)

  # Find all markdown files, excluding any .archive directories
  find_cmd=(find "$target_dir" \( -type d -name '*.archive' -prune \) -o \( -type f -name '*.md' -print \))
  while IFS= read -r file; do
    archive_file "$file" "$cutoff_ts"
  done < <(lib::exec "${find_cmd[@]}")
}

archive_file() {
  local file cutoff_ts filedir base temp_file in_block modified
  local header_date header_ts year month day archive_dir archive_path
  file="$1"
  cutoff_ts="$2"
  filedir=$(dirname -- "$file")
  base=$(basename -- "$file" .md)
  temp_file=$(mktemp)
  trap 'rm -f "$temp_file"' EXIT

  in_block=0
  modified=0

  while IFS= read -r line; do
    # Match date headers in format *2023-01-01* or **2023-01-01**
    if [[ $line =~ ^\**([0-9]{4})-([0-9]{2})-([0-9]{2})\**$ ]]; then
      year="${BASH_REMATCH[1]}"
      month="${BASH_REMATCH[2]}"
      day="${BASH_REMATCH[3]}"
      header_date="$year-$month-$day"
      header_ts=$(lib::exec date --date="$header_date" +%s)

      if (( header_ts < cutoff_ts )); then
        if [[ $modified -eq 0 ]]; then
          log::info "Archiving: $file"
          modified=1
        fi
        archive_dir="$filedir/$year.archive"
        lib::exec mkdir -p "$archive_dir"
        archive_path="$archive_dir/$base.md"
        if [[ ! -f "$archive_path" ]]; then
          lib::exec touch "$archive_path"
        fi
        echo "$line" >> "$archive_path"
        in_block=1
      else
        echo "$line" >> "$temp_file"
        in_block=0
      fi

    elif [[ $in_block -eq 1 ]]; then
      echo "$line" >> "$archive_path"
    else
      echo "$line" >> "$temp_file"
    fi
  done < "$file"

  if [[ $modified -eq 1 ]]; then
    lib::exec mv "$temp_file" "$file"
    if [[ ! -s "$file" ]]; then
      log::info "Removing empty file: $file"
      lib::exec rm "$file"
    fi
  fi

  trap - EXIT
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
  fi
  local command
  command="$1"
  shift

  if [[ $command == archive ]]; then
    cmd_archive "$@"
  else
    usage
  fi
}

main "$@"
