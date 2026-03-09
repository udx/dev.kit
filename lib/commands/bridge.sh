#!/usr/bin/env bash

# @description: Show a basic bridge payload

dev_kit_cmd_bridge() {
  local format="${1:-text}"

  if [ "$format" = "json" ]; then
    printf '{\n  "command": "bridge",\n  "repo": "%s",\n  "capabilities": ["install", "status"],\n  "boundaries": ["local shell"]\n}\n' "$(pwd)"
    return 0
  fi

  echo "dev.kit bridge"
  echo "repo: $(pwd)"
  echo "capabilities: install, status"
  echo "boundaries: local shell"
}
