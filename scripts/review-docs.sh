#!/usr/bin/env sh
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
PROMPT_FILE="$ROOT_DIR/prompts/review-docs.md"
FEEDBACK_FILE="$DOCS_DIR/_feedback.md"
TREE_FILE="$DOCS_DIR/_tree.txt"

if [ ! -f "$PROMPT_FILE" ]; then
  printf "Missing prompt: %s\n" "$PROMPT_FILE" >&2
  exit 1
fi

if [ ! -f "$FEEDBACK_FILE" ]; then
  printf "Missing feedback file: %s\n" "$FEEDBACK_FILE" >&2
  exit 1
fi

find "$DOCS_DIR" -type f -print \
  | sed "s|^$ROOT_DIR/||" \
  | sort > "$TREE_FILE"

PROMPT_CONTENT="$(cat "$PROMPT_FILE")"
REPORT="$(codex exec "$PROMPT_CONTENT")"

{
  printf "\n\n---\n"
  printf "Review run: %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf "Input tree: %s\n" "docs/_tree.txt"
  printf "\n%s\n" "$REPORT"
} >> "$FEEDBACK_FILE"

printf "Wrote review report to %s\n" "$FEEDBACK_FILE"
printf "Wrote tree snapshot to %s\n" "$TREE_FILE"
