#!/usr/bin/env sh
set -euo pipefail

if [ $# -lt 1 ]; then
  printf "Usage: %s TASK_ID [title]\n" "$0" >&2
  exit 1
fi

TASK_ID="$1"
TITLE="${2:-$1}"
ROOT_DIR="$(pwd)"
BASE_DIR="$ROOT_DIR/.udx/dev.kit/workflows/$TASK_ID"
FILE="$BASE_DIR/workflow.md"

if [ -e "$FILE" ]; then
  printf "Workflow already exists: %s\n" "$FILE" >&2
  exit 1
fi

mkdir -p "$BASE_DIR"

cat > "$FILE" <<EOF2
# Workflow — $TITLE

done: false

## Bounded Work
- max_steps_per_iteration: 6
- max_files_per_step: 8
- max_new_files_per_iteration: 3
- max_move_operations_per_step: 0
- extract_child_workflow_if_any_exceeded: true

## Steps

1) Task: <short description>
   Input: <files or artifacts>
   Logic/Tooling: codex exec "<step prompt>"
   Expected output/result: <result>
   done: false
EOF2

printf "Workflow created: %s\n" "$FILE"
