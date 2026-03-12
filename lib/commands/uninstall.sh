#!/usr/bin/env bash

# @description: Remove the local dev.kit installation

dev_kit_cmd_uninstall() {
  local format="${1:-text}"
  shift || true

  if [ "$format" = "json" ]; then
    echo "JSON output is not supported for uninstall" >&2
    return 1
  fi

  "$REPO_DIR/bin/scripts/uninstall.sh" "$@"
}
