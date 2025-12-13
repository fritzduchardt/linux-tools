#!/usr/bin/bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  echo """Usage: $0 [OPTIONS] <markdown_file>

Renames images in the same directory as the given markdown file that are not
associated with any existing markdown file.

Images are renamed to <markdown_basename>_N.<ext>, ordered by creation time.

Options:
    -h    Show this help message

Examples:
    $0 document.md
    This will rename loose images in the directory of document.md to
    document_1.jpg, document_2.png, etc., sorted by creation time.
"""
}

collect_images_by_extension() {
  local md_dir="$1"
  lib::exec find "$md_dir" -maxdepth 1 -type f -iname "*.jpg" \
    -printf '%T@ %p\n' \
    | sort -n \
    | cut -d' ' -f2-
}

collect_markdown_basenames() {
  local md_dir="$1"
  lib::exec find "$md_dir" -maxdepth 1 -type f -iname "*.md" -exec basename\
 {} \;
}

is_image_associated_with_markdown() {
  local img_basename="$1"
  local md_basenames_str="$2"

  if [[ "$md_basenames_str" =~ $img_basename ]]; then
    return 0
  fi

  return 1
}

main() {
  local md_file="$1"
  local md_dir
  md_dir="$(dirname "$md_file")"
  local md_basename
  md_basename="$(basename "$md_file" .md)"

  local images_str
  images_str="$(collect_images_by_extension "$md_dir")"

  local md_basenames_str
  log::debug "Markdown directory: $md_dir"
  md_basenames_str="$(collect_markdown_basenames "$md_dir")"

  local count=1
  log::debug "Processing images: $images_str"
  while IFS= read -r img; do
    [[ -z "$img" ]] \
      && continue
    log::debug "Processing image: $img"
    local img_basename
    img_basename="$(basename "$img")"
    img_basename="${img_basename%.*}"

    if ! is_image_associated_with_markdown "$img_basename" \
      "$md_basenames_str"; then
      local ext
      ext="${img##*.}"
      local new_name
      new_name="${md_basename}_${count}.${ext}"

      log::info "Renaming '$img' to '$new_name'"
      lib::exec mv "$img" "$md_dir/$new_name"
      ((count++))
    fi
  done <<<"$images_str"
}

parse_arguments() {
  local md_file=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      *)
        if [[ -z "$md_file" ]]; then
          md_file="$1"
        else
          log::error "Unexpected argument: $1"
          usage
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$md_file" ]]; then
    log::error "Markdown file not provided."
    usage
    exit 1
  fi

  echo "$md_file"
}

MD_FILE=$(parse_arguments "$@")
main "$MD_FILE"
