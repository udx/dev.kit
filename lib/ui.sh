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

LOG_LIB="${LOG_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logging.sh}"
if [ -f "$LOG_LIB" ]; then
  # shellcheck disable=SC1090
  . "$LOG_LIB"
fi

ui_reset() {
  ui_color "0"
}

ui_blue() {
  ui_color "34"
}

ui_cyan() {
  ui_color "36"
}

ui_yellow() {
  ui_color "33"
}

ui_emerald() {
  ui_color "32"
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

ui_info() {
  local msg="$*"
  if command -v log_info >/dev/null 2>&1; then
    log_info "$msg"
    return
  fi
  printf "INFO %s\n" "$msg"
}

ui_error() {
  local msg="$*"
  if command -v log_error >/dev/null 2>&1; then
    log_error "$msg"
    return
  fi
  printf "ERROR %s\n" "$msg"
}
