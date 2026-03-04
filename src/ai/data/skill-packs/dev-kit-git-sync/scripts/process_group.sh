#!/usr/bin/env bash
set -euo pipefail

GROUP_NAME="$1"
PATTERN="$2"
TASK_ID="$3"
DRY_RUN="${4:-false}"
BASE_MESSAGE="${5:-}"

DRIFT_FILE=".drift.tmp"
PROCESSED_FILE=".processed.tmp"

if [[ ! -f "$DRIFT_FILE" ]]; then
  echo "Error: Drift file not found." >&2
  exit 1
fi

touch "$PROCESSED_FILE"

is_processed() {
  local f="$1"
  grep -Fqx "$f" "$PROCESSED_FILE"
}

files=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if ! is_processed "$f" && echo "$f" | grep -Eq "$PATTERN"; then
    files+=("$f")
  fi
done < "$DRIFT_FILE"

if [[ ${#files[@]} -eq 0 ]]; then
  exit 0
fi

commit_msg="${GROUP_NAME}: resolve drift for $TASK_ID"
if [[ -n "$BASE_MESSAGE" ]]; then
  commit_msg="${GROUP_NAME}: $BASE_MESSAGE ($TASK_ID)"
fi

echo "Step: Grouping [$GROUP_NAME] -> ${#files[@]} files"
for f in "${files[@]}"; do
  echo "  + $f"
  echo "$f" >> "$PROCESSED_FILE"
done

if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY-RUN] git add ${files[*]}"
  echo "  [DRY-RUN] git commit -m \"$commit_msg\""
else
  if git add "${files[@]}" && git commit -m "$commit_msg"; then
    echo "  [OK] Committed group: $GROUP_NAME"
  else
    echo "⚠️  [FAILOVER] Commit failed for group: $GROUP_NAME"
    echo "Status: Resilient Normalization (Manual Path)"
    echo "To resolve manually, run:"
    echo "  git add ${files[*]}"
    echo "  git commit -m \"$commit_msg\""
    # We exit with 0 to allow the rest of the workflow steps to try their luck
    # This is "Fail-Open" for the waterfall progression.
  fi
fi
echo ""
