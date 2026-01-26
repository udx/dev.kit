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

if [ -e "$TASK_DIR" ]; then
  printf "Task already exists: %s\n" "$TASK_DIR" >&2
  exit 1
fi

mkdir -p "$TASK_DIR"

cat > "$PROMPT_FILE" <<EOF2
# Task — $TASK_ID
status: draft
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Scope
- <short scope statement>

## Inputs
- <paths or artifacts>

## Outputs
- <expected artifacts>

## Constraints
- deterministic
- tool-neutral
- no execution

## Request
<task instructions>
EOF2

cat > "$FEEDBACK_FILE" <<EOF2
# Feedback — $TASK_ID
status: pending

## Output
- <request|command|artifact|workflow>

## Notes
EOF2

printf "Task initialized: %s\n" "$TASK_DIR"
printf "Prompt: %s\n" "$PROMPT_FILE"
printf "Feedback: %s\n" "$FEEDBACK_FILE"
