#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="${1:-}"

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: $0 <skill-name>" >&2
  exit 2
fi

SKILL_DIR="$HOME/.codex/skills/$SKILL_NAME"

if [ ! -d "$SKILL_DIR" ]; then
  echo "Missing skill dir: $SKILL_DIR" >&2
  exit 1
fi

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "Missing SKILL.md: $SKILL_DIR/SKILL.md" >&2
  exit 1
fi

echo "OK: $SKILL_DIR"
