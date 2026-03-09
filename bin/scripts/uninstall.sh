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

confirm_action() {
  local msg="$1"
  if [ -t 0 ]; then
    printf "%s [y/N] " "$msg"
    read -r answer || true
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      *) return 1 ;;
    esac
  fi
  return 0
}

if [ -L "$TARGET" ] || [ -f "$TARGET" ]; then
  if confirm_action "Remove dev.kit binary from $TARGET?"; then
    rm -f "$TARGET"
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Removed" "$TARGET"
    else
      echo "Removed: $TARGET"
    fi
  fi
else
  echo "Binary not found at $TARGET"
fi

if [ -d "$ENGINE_DIR" ]; then
  if [ "${1:-}" = "--purge" ] || confirm_action "Purge dev.kit engine directory ($ENGINE_DIR)?"; then
    if confirm_action "Backup state before purging?"; then
      ts=$(date +%Y%m%d_%H%M%S)
      backup_path="$HOME/dev-kit-state-backup-${ts}.tar.gz"
      tar -czf "$backup_path" -C "$ENGINE_DIR" . 2>/dev/null || true
      echo "State backed up to $backup_path"
    fi
    rm -rf "$ENGINE_DIR"
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Purged" "$ENGINE_DIR"
    else
      echo "Purged: $ENGINE_DIR"
    fi
  fi
fi

