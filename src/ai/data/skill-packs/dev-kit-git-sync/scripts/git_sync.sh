#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: git_sync.sh [options]

Options:
  --dry-run      Show what commits would be made without executing them.
  --task-id <id> The current task ID to associate with commits.
  --message <m>  Optional base message.
  -h, --help     Show this help message.

Behavior:
1. Identifies the "Drift" using git status.
2. Groups changes logically (Docs, AI, CLI, Core).
3. Performs atomic, logical commits.
USAGE
}

DRY_RUN="false"
TASK_ID="unknown"
BASE_MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN="true"; shift ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --message) BASE_MESSAGE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not a git repository." >&2
  exit 1
fi

echo "--- dev.kit Git Sync: Resolving Drift ---"

get_drift() {
    local staged unstaged untracked
    staged=$(git diff --name-only --cached)
    unstaged=$(git diff --name-only)
    untracked=$(git ls-files --others --exclude-standard)
    echo "$staged $unstaged $untracked" | tr ' ' '\n' | sort -u
}

DRIFT=$(get_drift)

if [[ -z "$DRIFT" ]]; then
  echo "No drift detected. Repository is clean."
  exit 0
fi

GROUP_NAMES=("docs" "ai" "cli" "core")
# Mutually exclusive patterns using grep -v to exclude previous groups
GROUP_PATTERNS=(
  "^docs/|^README.md" 
  "^src/ai/|^.gemini/" 
  "^bin/|^lib/|^src/cli/"
  "^src/|^environment.yaml|^context7.json"
)

# Keep track of processed files
PROCESSED_FILES=()

is_processed() {
  local f="$1"
  for p in "${PROCESSED_FILES[@]}"; do
    [[ "$f" == "$p" ]] && return 0
  done
  return 1
}

process_group() {
  local name="$1"
  local pattern="$2"
  local files=()

  for f in $DRIFT; do
    if ! is_processed "$f" && echo "$f" | grep -Eq "$pattern"; then
      files+=("$f")
      PROCESSED_FILES+=("$f")
    fi
  done

  if [[ ${#files[@]} -eq 0 ]]; then
    return
  fi

  local commit_msg="${name}: resolve drift for $TASK_ID"
  if [[ -n "$BASE_MESSAGE" ]]; then
    commit_msg="${name}: $BASE_MESSAGE ($TASK_ID)"
  fi

  echo "Group: [$name] -> ${#files[@]} files"
  for f in "${files[@]}"; do
    echo "  + $f"
  done

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY-RUN] git add ${files[*]}"
    echo "  [DRY-RUN] git commit -m \"$commit_msg\""
  else
    git add "${files[@]}"
    git commit -m "$commit_msg"
    echo "  [OK] Committed group: $name"
  fi
  echo ""
}

for i in "${!GROUP_NAMES[@]}"; do
  process_group "${GROUP_NAMES[$i]}" "${GROUP_PATTERNS[$i]}"
done

# Handle remaining files (Miscellaneous)
REMAINING_DRIFT=""
for f in $DRIFT; do
  if ! is_processed "$f"; then
    REMAINING_DRIFT="$REMAINING_DRIFT $f"
  fi
done

if [[ -n "$REMAINING_DRIFT" ]]; then
  echo "Processing remaining miscellaneous drift..."
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY-RUN] git add $REMAINING_DRIFT"
    echo "  [DRY-RUN] git commit -m \"misc: resolve remaining drift ($TASK_ID)\""
  else
    git add $REMAINING_DRIFT
    git commit -m "misc: resolve remaining drift ($TASK_ID)"
    echo "  [OK] Committed remaining drift."
  fi
fi

echo "--- Git Sync Complete ---"
