#!/usr/bin/env bash
set -euo pipefail

DEV_KIT_BIN_DIR="${DEV_KIT_BIN_DIR:-$HOME/.local/bin}"
DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"
TARGET="${DEV_KIT_BIN_DIR}/dev.kit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null && pwd || true)"

if [ -f "$REPO_DIR/lib/modules/output.sh" ]; then
  # shellcheck disable=SC1090
  . "$REPO_DIR/lib/modules/output.sh"
fi

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
  if command -v dev_kit_output_title >/dev/null 2>&1; then
    dev_kit_output_title "Removed dev.kit"
    dev_kit_output_section "uninstall"
    dev_kit_output_row "binary" "$TARGET"
  else
    echo "Removed binary: $TARGET"
  fi
else
  if command -v dev_kit_output_title >/dev/null 2>&1; then
    dev_kit_output_title "Removed dev.kit"
    dev_kit_output_section "uninstall"
    dev_kit_output_row "binary" "not found: $TARGET"
  else
    echo "Binary not found: $TARGET"
  fi
fi

if [ -d "$DEV_KIT_HOME" ]; then
  rm -rf "$DEV_KIT_HOME"
  if command -v dev_kit_output_row >/dev/null 2>&1; then
    dev_kit_output_row "home" "$DEV_KIT_HOME"
  else
    echo "Removed home: $DEV_KIT_HOME"
  fi
else
  if command -v dev_kit_output_row >/dev/null 2>&1; then
    dev_kit_output_row "home" "not found: $DEV_KIT_HOME"
  else
    echo "Home not found: $DEV_KIT_HOME"
  fi
fi

if command -v dev_kit_output_row >/dev/null 2>&1; then
  dev_kit_output_row "shell" "profile files were not modified"
else
  echo "Shell profile files were not modified."
fi
