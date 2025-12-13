#!/usr/bin/bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

MD_FILE=""

usage() {
    echo """Usage: $0 [OPTIONS] <markdown_file>

Renames images in the same directory as the given markdown file that are not associated with any existing markdown file.

Images are renamed to <markdown_basename>_N.<ext>, ordered by creation time.

Options:
    -h    Show this help message

Examples:
    $0 document.md
    This will rename loose images in the directory of document.md to document_1.jpg, document_2.png, etc., sorted by creation time.
"""
}

main() {
    local md_file="$1"
    if [[ ! -f "$md_file" ]]; then
        log::error "File '$md_file' does not exist or is not a file."
        exit 1
    fi
    local md_dir="$(dirname "$md_file")"
    local md_basename="$(basename "$md_file" .md)"
    local image_exts="jpg jpeg png"
    local images=()
    for ext in $image_exts; do
        while IFS= read -r -d '' file; do
            images+=("$file")
        done < <(lib::exec find "$md_dir" -maxdepth 1 -type f -iname "*.${ext}" -print0)
    done
    local sorted_images=()
    while IFS= read -r line; do
        sorted_images+=("$line")
    done < <(for img in "${images[@]}"; do
        mtime=$(lib::exec stat -c '%Y' "$img")
        echo "$mtime $img"
    done | lib::exec sort -n | cut -d' ' -f2- )
    local md_basenames=()
    while IFS= read -r -d '' file; do
        md_basenames+=("$(basename "$file" .md)")
    done < <(lib::exec find "$md_dir" -maxdepth 1 -type f -iname "*.md" -print0)
    local count=1
    for img in "${sorted_images[@]}"; do
        local img_basename="$(basename "$img")"
        img_basename="${img_basename%.*}"
        if [[ ! " ${md_basenames[*]} " =~ " ${img_basename} " ]]; then
            local ext="${img##*.}"
            local new_name="${md_basename}_${count}.${ext}"
            log::info "Renaming '$img' to '$new_name'"
            lib::exec mv "$img" "$md_dir/$new_name"
            ((count++))
        fi
    done
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$MD_FILE" ]]; then
                MD_FILE="$1"
            else
                log::error "Unexpected argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$MD_FILE" ]]; then
    log::error "Markdown file not provided."
    usage
    exit 1
fi

main "$MD_FILE"
