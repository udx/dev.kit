#!/usr/bin/env bash

# @description: Compatibility alias for action --refresh-context

dev_kit_cmd_save() {
  local format="${1:-text}"

  shift || true
  dev_kit_cmd_action "$format" --refresh-context "$@"
}
