#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/lib/modules/bootstrap.sh"
dev_kit_bootstrap

TARGET="${DEV_KIT_BIN_DIR}/dev.kit"

if [ "$#" -gt 0 ]; then
  echo "This installer does not modify shell profiles." >&2
  echo "Usage: bash bin/scripts/install.sh" >&2
  exit 1
fi

mkdir -p "$DEV_KIT_HOME" "$DEV_KIT_BIN_DIR"
rm -rf "$DEV_KIT_HOME/bin" "$DEV_KIT_HOME/lib" "$DEV_KIT_HOME/src" "$DEV_KIT_HOME/config" "$DEV_KIT_HOME/source" "$DEV_KIT_HOME/state"

dev_kit_copy_tree "$REPO_DIR/bin" "$DEV_KIT_HOME/bin"
dev_kit_copy_tree "$REPO_DIR/lib" "$DEV_KIT_HOME/lib"
dev_kit_copy_tree "$REPO_DIR/src" "$DEV_KIT_HOME/src"

find "$DEV_KIT_HOME/bin" -type f -exec chmod +x {} \;

ln -sfn "$DEV_KIT_HOME/bin/dev-kit" "$TARGET"

echo "Installed dev.kit"
echo "binary: $TARGET"
echo "home:   $DEV_KIT_HOME"
if dev_kit_path_contains_bin_dir; then
  echo "shell:  PATH already includes $DEV_KIT_BIN_DIR"
else
  echo "shell:  unchanged"
  echo "next:   export PATH=\"$DEV_KIT_BIN_DIR:\$PATH\""
  echo "then:   source \"$DEV_KIT_HOME/bin/env/dev-kit.sh\""
fi
