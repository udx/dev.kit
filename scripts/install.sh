#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
TARGET="${BIN_DIR}/dev-kit"
ENGINE_DIR="${HOME}/.engineering/dev-kit"
ENV_SRC="${REPO_DIR}/env/dev-kit.sh"
ENV_DST="${ENGINE_DIR}/env.sh"
CONFIG_SRC="${REPO_DIR}/config/default.env"
CONFIG_DST="${ENGINE_DIR}/config.env"

mkdir -p "$BIN_DIR"
mkdir -p "$ENGINE_DIR"

if [ -e "$TARGET" ]; then
  echo "dev-kit already installed at $TARGET"
else
  ln -s "${REPO_DIR}/bin/dev-kit" "$TARGET"
  echo "dev-kit installed: $TARGET"
fi

if [ -f "$ENV_SRC" ]; then
  cp "$ENV_SRC" "$ENV_DST"
  echo "dev-kit env installed: $ENV_DST"
fi

if [ -f "$CONFIG_SRC" ] && [ ! -f "$CONFIG_DST" ]; then
  cp "$CONFIG_SRC" "$CONFIG_DST"
  echo "dev-kit config installed: $CONFIG_DST"
fi

# Optional PATH hint
if ! command -v dev-kit >/dev/null 2>&1; then
  echo "Add this to your shell profile if needed:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
fi

echo "To enable auto-init, run:"
echo "  dev-kit enable --shell=bash"
