#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: export_svg.sh <input.mmd> <output.svg>

Behavior:
- Validates Mermaid CLI presence
- Never overwrites existing files; appends -N suffix
- Emits actionable sandbox/runtime hints on failure
USAGE
}

fail() {
  echo "ERROR[$1] $2" >&2
  exit "$3"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 64
fi

input_path="$1"
requested_output="$2"

if [[ ! -f "$input_path" ]]; then
  fail "MISSING_INPUT" "Input Mermaid file not found: $input_path" 66
fi

if ! command -v mmdc >/dev/null 2>&1; then
  fail "MMDC_NOT_FOUND" "Mermaid CLI (mmdc) is not installed. Install with: npm install -g @mermaid-js/mermaid-cli" 69
fi

normalize_output_path() {
  local p="$1"
  if [[ "$p" != *.svg ]]; then
    p="${p}.svg"
  fi
  echo "$p"
}

next_available_path() {
  local p="$1"
  if [[ ! -e "$p" ]]; then
    echo "$p"
    return
  fi

  local stem="${p%.svg}"
  local i=1
  local candidate
  while :; do
    candidate="${stem}-${i}.svg"
    if [[ ! -e "$candidate" ]]; then
      echo "$candidate"
      return
    fi
    i=$((i + 1))
  done
}

output_path="$(normalize_output_path "$requested_output")"
output_path="$(next_available_path "$output_path")"

mkdir -p "$(dirname "$output_path")"

tmp_err="$(mktemp)"
trap 'rm -f "$tmp_err"' EXIT

if ! mmdc -i "$input_path" -o "$output_path" 2>"$tmp_err"; then
  cat "$tmp_err" >&2

  if grep -Eiq "no usable sandbox|setuid|zygote|sandbox" "$tmp_err"; then
    echo "Hint: Chromium sandbox issue detected." >&2
    echo "Retry with a Puppeteer config containing args: [\"--no-sandbox\",\"--disable-setuid-sandbox\"]." >&2
    echo "Example: mmdc -p puppeteer-config.json -i $input_path -o $output_path" >&2
  fi

  fail "MMDC_FAILED" "mmdc execution failed." 70
fi

echo "$output_path"
