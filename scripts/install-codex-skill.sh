#!/usr/bin/env bash
set -euo pipefail

SKILL_SRC="${1:-}"
SKILL_NAME="${2:-}"
SKILLS_DIR="${3:-}"

if [ -z "$SKILL_SRC" ] || [ -z "$SKILL_NAME" ] || [ -z "$SKILLS_DIR" ]; then
  echo "Usage: $0 <skill-src-dir> <skill-name> <skills-dir>" >&2
  exit 2
fi

if [ ! -d "$SKILL_SRC" ]; then
  echo "Missing skill source dir: $SKILL_SRC" >&2
  exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
  mkdir -p "$SKILLS_DIR"
  echo "Created: $SKILLS_DIR"
else
  echo "Exists: $SKILLS_DIR"
fi

SKILL_DEST="$SKILLS_DIR/$SKILL_NAME"
cp -R "$SKILL_SRC" "$SKILL_DEST"

if [ ! -f "$SKILL_DEST/SKILL.md" ]; then
  echo "Missing SKILL.md in: $SKILL_DEST" >&2
  exit 1
fi

echo "Installed: $SKILL_DEST"
