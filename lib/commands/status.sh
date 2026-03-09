#!/usr/bin/env bash

# @description: Show basic installation status

dev_kit_cmd_status() {
  local format="${1:-text}"
  local state="not installed"

  if [ -d "$DEV_KIT_HOME" ]; then
    state="installed"
  fi

  if [ "$format" = "json" ]; then
    printf '{\n  "name": "dev.kit",\n  "home": "%s",\n  "state": "%s"\n}\n' "$DEV_KIT_HOME" "$state"
    return 0
  fi

  echo "dev.kit"
  echo "home: $DEV_KIT_HOME"
  echo "state: $state"
}
