#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/lib/modules/bootstrap.sh"
dev_kit_bootstrap "$REPO_DIR"

TARGET="${DEV_KIT_BIN_DIR}/dev.kit"

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
