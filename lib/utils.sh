#!/usr/bin/env bash

dev_kit_warn() {
  echo "$*" >&2
}

dev_kit_require_cmd() {
  local cmd="${1:-}"
  local context="${2:-}"
  if [ -z "$cmd" ]; then
    dev_kit_warn "Missing required command name."
    return 1
  fi
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if [ -n "$context" ]; then
    dev_kit_warn "$cmd is required for $context."
  else
    dev_kit_warn "$cmd is required."
  fi
  dev_kit_warn "Install $cmd locally or run the task in the worker container (see udx/worker-deployment)."
  return 1
}
