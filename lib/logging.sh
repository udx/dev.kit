#!/bin/bash

# Features:
# - log levels: debug, info, warn, error, fatal
# - log format: <timestamp> <level> <message>
# - log to file and stdout (plain text)

log_ts() {
  date -Iseconds
}

log_level_rank() {
  case "$1" in
    DEBUG) echo 10 ;;
    INFO) echo 20 ;;
    WARN) echo 30 ;;
    ERROR) echo 40 ;;
    FATAL) echo 50 ;;
    *) echo 20 ;;
  esac
}

log_should_log() {
  local level="$1"
  local min_level="${DEV_KIT_LOG_LEVEL:-INFO}"
  local level_rank
  local min_rank
  level_rank="$(log_level_rank "$level")"
  min_rank="$(log_level_rank "$min_level")"
  [ "$level_rank" -ge "$min_rank" ]
}

log_write() {
  local level="$1"
  shift
  local msg="$*"
  if ! log_should_log "$level"; then
    return 0
  fi
  local line
  line="$(log_ts) [$level] $msg"
  if [ -n "${DEV_KIT_LOG_FILE:-}" ]; then
    printf "%s\n" "$line" >> "$DEV_KIT_LOG_FILE"
  fi
  printf "%s\n" "$line"
}

log_debug() { log_write "DEBUG" "$@"; }
log_info() { log_write "INFO" "$@"; }
log_warn() { log_write "WARN" "$@"; }
log_error() { log_write "ERROR" "$@"; }
log_fatal() { log_write "FATAL" "$@"; }
