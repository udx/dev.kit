#!/usr/bin/env sh
set -euo pipefail

if [ $# -lt 1 ]; then
  printf "Usage: %s TASK_ID\n" "$0" >&2
  exit 1
fi

TASK_ID="$1"
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TASK_DIR="$ROOT_DIR/tasks/$TASK_ID"
PROMPT_FILE="$TASK_DIR/prompt.md"
FEEDBACK_FILE="$TASK_DIR/feedback.md"

if [ ! -f "$PROMPT_FILE" ]; then
  printf "Missing prompt: %s\n" "$PROMPT_FILE" >&2
  exit 1
fi

if [ ! -f "$FEEDBACK_FILE" ]; then
  printf "Missing feedback file: %s\n" "$FEEDBACK_FILE" >&2
  exit 1
fi

PROMPT_CONTENT="$(cat "$PROMPT_FILE")"
REPORT="$(codex exec "$PROMPT_CONTENT")"

{
  printf "\n\n---\n"
  printf "run: %s\n\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf "%s\n" "$REPORT"
} >> "$FEEDBACK_FILE"

printf "Feedback written: %s\n" "$FEEDBACK_FILE"
