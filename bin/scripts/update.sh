#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_LIB="${REPO_DIR}/lib/ui.sh"
if [ -f "$UI_LIB" ]; then
  # shellcheck disable=SC1090
  . "$UI_LIB"
fi

if [ -d "$REPO_DIR/.git" ]; then
  if command -v ui_header >/dev/null 2>&1; then
    ui_header "dev.kit | update"
  else
    echo "dev.kit update"
  fi
  git -C "$REPO_DIR" pull --rebase
  "$REPO_DIR/bin/scripts/install.sh"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Updated" "$REPO_DIR"
  else
    echo "dev.kit updated."
  fi
else
  if command -v ui_warn >/dev/null 2>&1; then
    ui_warn "Not a git install" "Reinstall using the one-liner or bin/scripts/install.sh."
  else
    echo "This dev.kit install is not git-based."
    echo "Reinstall using the one-liner or bin/scripts/install.sh."
  fi
fi
