#!/usr/bin/env bash
set -euo pipefail

input_dir="${1:-}"
output_dir="${2:-}"

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
  echo "Usage: convert-all.sh <input-dir> <output-dir>" >&2
  exit 1
fi

mkdir -p "$output_dir"

shopt -s nullglob
for file in "$input_dir"/*.mmd; do
  base="$(basename "$file" .mmd)"
  mmdc -i "$file" -o "$output_dir/$base.svg"
  echo "Converted $file -> $output_dir/$base.svg"
done
