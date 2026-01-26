#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_LIB="${REPO_DIR}/lib/ui.sh"
if [ -f "$UI_LIB" ]; then
  # shellcheck disable=SC1090
  . "$UI_LIB"
fi

BIN_DIR="${HOME}/.local/bin"
TARGET="${BIN_DIR}/dev.kit"
DEV_KIT_OWNER="${DEV_KIT_OWNER:-udx}"
DEV_KIT_REPO="${DEV_KIT_REPO:-dev.kit}"
ENGINE_DIR="${HOME}/.${DEV_KIT_OWNER}/${DEV_KIT_REPO}"

if [ -L "$TARGET" ] || [ -f "$TARGET" ]; then
  rm -f "$TARGET"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Removed" "$TARGET"
  else
    echo "Removed: $TARGET"
  fi
else
  if command -v ui_warn >/dev/null 2>&1; then
    ui_warn "Not found" "$TARGET"
  else
    echo "Not found: $TARGET"
  fi
fi

if [ "${1:-}" = "--purge" ]; then
  rm -rf "$ENGINE_DIR"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Purged" "$ENGINE_DIR"
  else
    echo "Purged: $ENGINE_DIR"
  fi
fi
