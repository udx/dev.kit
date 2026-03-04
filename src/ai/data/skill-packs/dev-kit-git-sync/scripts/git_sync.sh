#!/usr/bin/env bash
set -euo pipefail

# dev.kit Git Sync: Workflow-based Logic
# This script executes the steps defined in workflow.yaml

usage() {
  cat <<'USAGE'
Usage: git_sync.sh [options]

Options:
  --dry-run      Show what commits would be made without executing them.
  --task-id <id> The current task ID to associate with commits.
  --message <m>  Optional base message prefix.
  -h, --help     Show this help message.
USAGE
}

DRY_RUN="false"
TASK_ID="unknown"
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN="true"; shift ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_FILE="${SCRIPT_DIR}/../workflow.yaml"

echo "--- dev.kit Git Sync: Starting Workflow ---"
[ -f "$WORKFLOW_FILE" ] && echo "Loading: $(basename "$WORKFLOW_FILE")"

# Internal Step: Detect
staged=$(git diff --name-only --cached)
unstaged=$(git diff --name-only)
untracked=$(git ls-files --others --exclude-standard)
echo "$staged $unstaged $untracked" | tr ' ' '\n' | sort -u > .drift.tmp
: > .processed.tmp # Reset processed tracking

# Step Runner
run_step() {
  local id="$1"
  local name="$2"
  local pattern="$3"
  echo "--- Step: $name ($id) ---"
  bash "${SCRIPT_DIR}/process_group.sh" "$id" "$pattern" "$TASK_ID" "$DRY_RUN" "$MESSAGE"
}

# Steps (Mirrored from workflow.yaml)
run_step "docs" "Group Documentation" "^docs/|^README.md"
run_step "ai" "Group AI & Integrations" "^src/ai/|^.gemini/"
run_step "cli" "Group CLI & Scripts" "^bin/|^lib/|^src/cli/"
run_step "core" "Group Core Infrastructure" "^src/|^environment.yaml|^context7.json"

# Final step: Remaining
REMAINING=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if ! grep -Fqx "$f" .processed.tmp; then
    REMAINING="$REMAINING $f"
  fi
done < .drift.tmp

if [[ -n "$REMAINING" ]]; then
  echo "--- Step: Miscellaneous Drift ---"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY-RUN] git add $REMAINING"
    echo "  [DRY-RUN] git commit -m \"misc: resolve remaining drift ($TASK_ID)\""
  else
    git add $REMAINING
    git commit -m "misc: resolve remaining drift ($TASK_ID)"
    echo "  [OK] Committed remaining drift."
  fi
fi

# Cleanup
rm -f .drift.tmp .processed.tmp
echo "--- Git Sync Workflow Complete ---"
