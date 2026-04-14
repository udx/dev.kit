#!/usr/bin/env bash

DEV_KIT_OUTPUT_LABEL_WIDTH="${DEV_KIT_OUTPUT_LABEL_WIDTH:-18}"

dev_kit_output_title() {
  printf '%s\n' "$1"
}

dev_kit_output_section() {
  printf '\n[%s]\n' "$1"
}

dev_kit_output_row() {
  local label="$1"
  local value="${2:-}"

  printf '  %-*s %s\n' "$DEV_KIT_OUTPUT_LABEL_WIDTH" "${label}:" "$value"
}

dev_kit_output_summary() {
  local value="${1:-}"
  printf '\n> %s\n' "$value"
}

dev_kit_output_list_item() {
  printf '  - %s\n' "$1"
}

dev_kit_output_list_from_lines() {
  local item=""

  while IFS= read -r item; do
    [ -n "$item" ] || continue
    dev_kit_output_list_item "$item"
  done
}

dev_kit_output_kv_list_from_pipe() {
  local line=""
  local key=""
  local value=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    key="${line%%|*}"
    value="${line#*|}"
    dev_kit_output_row "$key" "$value"
  done
}

dev_kit_output_first_lines() {
  local max_items="${1:-3}"
  local line=""
  local count=0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    printf '%s\n' "$line"
    count=$((count + 1))
    if [ "$count" -ge "$max_items" ]; then
      break
    fi
  done
}

# ── Spinner ───────────────────────────────────────────────────────────────────
# Background Braille spinner for long-running operations.
# Writes to stderr so it works even when stdout is redirected to a file.
# Skipped in non-interactive environments (CI, no TTY).

_DEV_KIT_SPINNER_PID=""

dev_kit_spinner_start() {
  local msg="${1:-}"
  [ -t 2 ] || return 0
  printf '  ⠋ %s' "$msg" >&2
  (
    set +e
    trap 'exit 0' TERM INT HUP
    while :; do
      for c in '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'; do
        printf '\r  %s %s' "$c" "$msg" >&2
        sleep 0.1 2>/dev/null || sleep 1
      done
    done
  ) &
  _DEV_KIT_SPINNER_PID=$!
}

dev_kit_spinner_stop() {
  local result="${1:-}"
  if [ -n "${_DEV_KIT_SPINNER_PID:-}" ]; then
    kill "$_DEV_KIT_SPINNER_PID" 2>/dev/null
    wait "$_DEV_KIT_SPINNER_PID" 2>/dev/null || true
    _DEV_KIT_SPINNER_PID=""
  fi
  [ -t 2 ] || return 0
  if [ -n "$result" ]; then
    printf '\r  ✓ %-40s\n' "$result" >&2
  else
    printf '\r%-50s\r' '' >&2
  fi
}

# ── Status-aware factor row ───────────────────────────────────────────────────

dev_kit_output_status_row() {
  local label="$1"
  local status="$2"
  local icon=""
  case "$status" in
    present)        icon="✓" ;;
    partial)        icon="◦" ;;
    missing)        icon="✗" ;;
    not_applicable) icon="·" ; status="n/a" ;;
    *)              icon=" " ;;
  esac
  printf '  %-*s %s %s\n' "$DEV_KIT_OUTPUT_LABEL_WIDTH" "${label}:" "$icon" "$status"
}

# ── Navigation hint ───────────────────────────────────────────────────────────

dev_kit_output_hint() {
  printf '  %s %s\n' "→" "$1"
}
