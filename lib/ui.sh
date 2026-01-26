#!/bin/bash

ui_color() {
  local code="$1"
  if [ "${DEV_KIT_COLOR:-}" = "0" ]; then
    return
  fi
  if [ -z "${DEV_KIT_COLOR:-}" ] && [ -z "${NO_COLOR:-}" ] && [ -n "${TERM:-}" ] && [ "${TERM}" != "dumb" ]; then
    printf '\033[%sm' "$code"
    return
  fi
  if [ "${DEV_KIT_COLOR:-}" = "1" ] || { [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; }; then
    printf '\033[%sm' "$code"
  fi
}

ui_reset() {
  ui_color "0"
}

ui_dim() {
  ui_color "2"
}

ui_cyan() {
  ui_color "36"
}

ui_magenta() {
  ui_color "35"
}

ui_yellow() {
  ui_color "33"
}

ui_emerald() {
  ui_color "32"
}

ui_orange() {
  ui_color "38;5;208"
}

ui_banner() {
  local brand="${1:-dev.kit}"
  local c1 c2 c3 c4 r d left right
  c1="$(ui_cyan)"
  c2="$(ui_magenta)"
  c3="$(ui_orange)"
  c4="$(ui_emerald)"
  r="$(ui_reset)"
  d="$(ui_dim)"

  if [[ "$brand" == *.* ]]; then
    left="${brand%%.*}"
    right=".${brand#*.}"
  else
    left="$brand"
    right=""
  fi

  printf "\n"
  printf "%s%s%s%s%s\n" "$c1" "$left" "$c2" "$right" "$r"
  printf "%s%s%s\n" "$d" "ready to run" "$r"
  printf "%s%s%s\n" "$c3" "  run:" "$r"
  printf "    %sdev.kit exec \"...\"%s\n" "$c4" "$r"
  printf "%s%s%s\n" "$c3" "  config:" "$r"
  printf "    %sdev.kit config show%s\n" "$c4" "$r"
}

ui_header() {
  local title="$1"
  local c
  c="$(ui_cyan)"
  e="$(ui_emerald)"

  # Get title length
  local title_len=${#title}

  # Build underline based on title length
  local underline=""
  for i in $(seq 1 $title_len); do
    underline="$underline-"
  done

  printf "\n"
  printf "%s› %s%s\n" "$e" "UDX" "$(ui_reset)"
  printf "%s› %s%s\n" "$c" "$title" "$(ui_reset)"
  printf "%s  %s%s\n" "$c" "$underline" "$(ui_reset)"
  printf "\n"
}

ui_section() {
  local title="$1"
  local c
  c="$(ui_yellow)"
  printf "\n%s%s%s\n" "$c" "$title" "$(ui_reset)"
}

ui_ok() {
  local label="$1"
  local detail="${2:-}"
  printf "OK  %s\n" "$label"
  if [ -n "$detail" ]; then
    printf "   %s\n" "$detail"
  fi
}

ui_warn() {
  local label="$1"
  local detail="${2:-}"
  printf "WARN %s\n" "$label"
  if [ -n "$detail" ]; then
    printf "   %s\n" "$detail"
  fi
}
