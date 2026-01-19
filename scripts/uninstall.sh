#!/bin/bash
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
TARGET="${BIN_DIR}/dev-kit"
ENGINE_DIR="${HOME}/.engineering/dev-kit"

if [ -L "$TARGET" ] || [ -f "$TARGET" ]; then
  rm -f "$TARGET"
  echo "Removed: $TARGET"
else
  echo "Not found: $TARGET"
fi

if [ "${1:-}" = "--purge" ]; then
  rm -rf "$ENGINE_DIR"
  echo "Purged: $ENGINE_DIR"
fi
