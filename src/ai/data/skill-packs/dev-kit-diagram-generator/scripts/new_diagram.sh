#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: new_diagram.sh <diagram_type> <output.mmd>

Supported diagram_type values:
- auto
- flowchart
- sequence | sequenceDiagram
- state | stateDiagram-v2
- er | erDiagram

Behavior:
- Normalizes aliases (sequence/state/er)
- Uses template defaults (auto => flowchart)
- Never overwrites existing files; appends -N suffix
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

raw_type="$1"
requested_output="$2"

normalize_type() {
  case "$1" in
    auto) echo "flowchart" ;;
    flowchart) echo "flowchart" ;;
    sequence|sequenceDiagram) echo "sequenceDiagram" ;;
    state|stateDiagram-v2) echo "stateDiagram-v2" ;;
    er|erDiagram) echo "erDiagram" ;;
    *) return 1 ;;
  esac
}

if ! diagram_type="$(normalize_type "$raw_type")"; then
  fail "UNSUPPORTED_TYPE" "Unsupported diagram type: $raw_type. Allowed: auto, flowchart, sequenceDiagram, stateDiagram-v2, erDiagram." 65
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
template_dir="$skill_dir/assets/templates"

case "$diagram_type" in
  flowchart) template="$template_dir/default-flowchart.mmd" ;;
  sequenceDiagram) template="$template_dir/default-sequence.mmd" ;;
  stateDiagram-v2) template="$template_dir/default-state.mmd" ;;
  erDiagram) template="$template_dir/default-er.mmd" ;;
  *) fail "INTERNAL_TYPE" "Internal type mapping failed: $diagram_type" 70 ;;
esac

if [[ ! -s "$template" ]]; then
  fail "MISSING_TEMPLATE" "Template missing or empty: $template" 66
fi

if grep -qi '^TODO:' "$template"; then
  fail "PLACEHOLDER_TEMPLATE" "Template is placeholder-only and must be replaced first: $template" 67
fi

normalize_output_path() {
  local p="$1"
  if [[ "$p" != *.mmd ]]; then
    p="${p}.mmd"
  fi
  echo "$p"
}

next_available_path() {
  local p="$1"
  if [[ ! -e "$p" ]]; then
    echo "$p"
    return
  fi

  local stem="${p%.mmd}"
  local i=1
  local candidate
  while :; do
    candidate="${stem}-${i}.mmd"
    if [[ ! -e "$candidate" ]]; then
      echo "$candidate"
      return
    fi
    i=$((i + 1))
  done
}

target_output="$(normalize_output_path "$requested_output")"
final_output="$(next_available_path "$target_output")"

mkdir -p "$(dirname "$final_output")"
cp "$template" "$final_output"

echo "$final_output"
