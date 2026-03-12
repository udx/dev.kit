#!/usr/bin/env bash
set -euo pipefail

DEV_KIT_BIN_DIR="${DEV_KIT_BIN_DIR:-$HOME/.local/bin}"
DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"
TARGET="${DEV_KIT_BIN_DIR}/dev.kit"

confirm_uninstall() {
  local reply=""
  printf 'Remove dev.kit from %s and %s? [y/N] ' "$TARGET" "$DEV_KIT_HOME" >&2
  read -r reply || true
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) echo "Cancelled." >&2; return 1 ;;
  esac
}

if [ "${1:-}" = "--yes" ]; then
  :
elif [ "$#" -gt 0 ]; then
  echo "Usage: uninstall.sh [--yes]" >&2
  exit 1
else
  confirm_uninstall || exit 1
fi

if [ -L "$TARGET" ] || [ -f "$TARGET" ]; then
  rm -f "$TARGET"
  echo "Removed binary: $TARGET"
else
  echo "Binary not found: $TARGET"
fi

if [ -d "$DEV_KIT_HOME" ]; then
  rm -rf "$DEV_KIT_HOME"
  echo "Removed home: $DEV_KIT_HOME"
else
  echo "Home not found: $DEV_KIT_HOME"
fi

echo "Shell profile files were not modified."
