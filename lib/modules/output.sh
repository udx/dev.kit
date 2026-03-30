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
