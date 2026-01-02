#!/usr/bin/bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

FOLDER_PATH=""
JPEGOPTIM_PERCENT="70"
CONVERT_PERCENT="50"

usage() {
  echo """Usage: $0 <folder>

Reduces JPEG size in a folder (non-recursive):
  1) jpegoptim --size=70% (approx target)
  2) convert -resize 50% (dimensions scaled)

Options:
  -h, --help              Show this help

Examples:
  $0 ./photos
"""
}

lib::exec() {
  "$@"
}

validate_args() {
  local folder="$1"

  if [[ -z "$folder" ]]; then
    log::error "Folder path is required"
    usage
    exit 2
  fi

  if [[ ! -d "$folder" ]]; then
    log::error "Folder path does not exist or is not a directory: $folder"
    exit 2
  fi
}

process_one_jpeg() {
  local file="$1"
  local dir="$2"
  local base=""
  local name=""
  local out=""

  base="$(basename -- "$file")"
  name="${base%.*}"
  out="$dir/$name.resized.jpg"

  log::info "Optimizing JPEG to about $JPEGOPTIM_PERCENT%: $file"
  lib::exec jpegoptim --quiet --preserve --size="$JPEGOPTIM_PERCENT%" "$file" \
    || true

  log::info "Resizing JPEG dimensions to $CONVERT_PERCENT%: $file -> $out"
  lib::exec convert "$file" -resize "$CONVERT_PERCENT%" "$out"
  lib::exec mv -f -- "$out" "$file"
}

process_folder() {
  local folder="$1"
  local file=""
  local found_any="false"

  shopt -s nullglob

  for file in "$folder"/*.jpg "$folder"/*.JPG "$folder"/*.jpeg "$folder"/*.JPEG; do
    found_any="true"
    process_one_jpeg "$file" "$folder"
  done

  shopt -u nullglob

  if [[ "$found_any" == "false" ]]; then
    log::warn "No JPEG files found in folder: $folder"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        FOLDER_PATH="${1:-}"
        shift
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  validate_args "$FOLDER_PATH"
  process_folder "$FOLDER_PATH"
  log::info "Done"
}

main "$@"
