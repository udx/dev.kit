#!/usr/bin/env sh
set -euo pipefail

if [ $# -lt 1 ]; then
  printf "Usage: %s TASK_ID\n" "$0" >&2
  exit 1
fi

TASK_ID="$1"
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
FEEDBACK_FILE="$ROOT_DIR/docs/_feedback.md"
WORKFLOW_DIR="$ROOT_DIR/workflows/$TASK_ID"
WORKFLOW_FILE="$WORKFLOW_DIR/workflow.md"

if [ ! -f "$FEEDBACK_FILE" ]; then
  printf "Missing feedback file: %s\n" "$FEEDBACK_FILE" >&2
  exit 1
fi

if ! rg -n "$TASK_ID" "$FEEDBACK_FILE" >/dev/null; then
  printf "Task ID not found in feedback: %s\n" "$TASK_ID" >&2
  exit 1
fi

mkdir -p "$WORKFLOW_DIR"

if [ ! -f "$WORKFLOW_FILE" ]; then
  cat > "$WORKFLOW_FILE" <<EOF
# Workflow — $TASK_ID

status: draft
source: docs/_feedback.md
scope: docs

## Purpose
Define a bounded, deterministic workflow for $TASK_ID.

## Inputs
- docs/_feedback.md
- docs/_tree.txt

## Rules
- Each step is bounded and deterministic.
- Steps produce artifacts only; execution requires explicit instruction.
- Intended edits are listed but not performed by this workflow.

## Steps

Step 1 — Clarify scope
done: false

Task:
Restate the task in a single sentence and identify required inputs.

Expected output/result:
- Scope statement
- Required input list

---

Step 2 — Produce artifact plan
done: false

Task:
Define the minimal artifacts to create or update.

Expected output/result:
- Artifact list with paths
- Constraints and invariants

---

Step 3 — Draft artifact changes
done: false

Task:
Draft the proposed content changes without applying them.

Expected output/result:
- Proposed edits summarized

---

Step 4 — Validation plan
done: false

Task:
Define verification steps and acceptance criteria.

Expected output/result:
- Validation checklist

## Intended File Edits (Proposed)
- <path>: <short intent>

## Notes
- Add task-specific details here.
EOF
else
  {
    printf "\n\n## Update Log\n"
    printf "- %s: Workflow touched by apply-task.sh for %s\n" \
      "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$TASK_ID"
  } >> "$WORKFLOW_FILE"
fi

printf "Workflow ready: %s\n" "$WORKFLOW_FILE"
printf "Intended edits (proposed only):\n"
rg -n "Intended File Edits" -A 5 "$WORKFLOW_FILE" || true
