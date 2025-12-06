#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  echo """
Usage: $0 [OPTIONS] PATH

Convert PDFs to text. For each PDF, attempts pdftotext first.
If output is empty, contains no alphanumeric characters, or pdftotext fails, converts the PDF to a single PNG and runs tesseract on that image.

PATH can be a single PDF file or a directory containing PDFs.

OPTIONS:
  -h    Show this help message

EXAMPLES:
  $0 document.pdf                    # Convert single PDF
  $0 /path/to/directory             # Convert all PDFs in directory
"""
}

process_pdf() {
  local pdf_path="$1"
  local base="${pdf_path%.pdf}"
  local txt_path="$base.txt"
  local img_path="$base.png"

  trap 'lib::exec rm -f "$img_path"' EXIT

  log::info "Processing $pdf_path"
  lib::exec rm -f "$txt_path"
  lib::exec rm -f "$img_path"

  if lib::exec pdftotext -layout "$pdf_path" "$txt_path"; then
    if [[ -s "$txt_path" ]] && grep -q '[[:alnum:]]' "$txt_path"; then
      log::info "Converted $pdf_path to text using pdftotext"
      trap - EXIT
      return 0
    else
      log::warn "pdftotext produced empty or non-alphanumeric output for $pdf_path"
    fi
  else
    log::warn "pdftotext failed for $pdf_path"
  fi

  log::warn "Falling back to image conversion and tesseract for $pdf_path"

  if lib::exec convert -density 300 "$pdf_path" -quality 100 -background white -alpha remove -append "$img_path"; then
    log::info "Converted $pdf_path to PNG $img_path"
  else
    log::error "Failed to convert $pdf_path to PNG"
    trap - EXIT
    return 1
  fi

  if lib::exec tesseract "$img_path" "$base" -l eng txt; then
    if [[ -s "$txt_path" ]] && lib::exec grep -q '[[:alnum:]]' "$txt_path"; then
      log::info "Converted $pdf_path to text using tesseract"
      trap - EXIT
      return 0
    else
      log::warn "Tesseract produced empty or non-alphanumeric output for $img_path"
      trap - EXIT
      return 1
    fi
  else
    log::error "Tesseract failed for $img_path"
    trap - EXIT
    return 1
  fi
}

process_path() {
  local path="$1"

  if [[ -f "$path" ]]; then
    if [[ "$path" == *.pdf ]]; then
      process_pdf "$path"
    else
      log::error "$path is not a PDF file"
    fi
  elif [[ -d "$path" ]]; then
    for file in "$path"/*.pdf; do
      if [[ -f "$file" ]]; then
        if ! process_pdf "$file"; then
          log::error "Failed to convert $file to text"
        fi
      fi
    done
  else
    log::error "$path is not a valid file or directory"
  fi
}

main() {
  local path=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        if [[ -z "$path" ]]; then
          path="$1"
        else
          log::error "Unexpected argument: $1"
          usage
          exit 1
        fi
        ;;
    esac
    shift
  done

  if [[ -z "$path" ]]; then
    log::error "PATH is required"
    usage
    exit 1
  fi

  process_path "$path"
}

main "$@"
