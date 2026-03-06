#!/usr/bin/env bash

# dev.kit Git Sync Module
# Core logic for logical, atomic repository synchronization and drift resolution.

# Process a group of files matching a pattern and commit them
# Usage: dev_kit_git_sync_process_group <name> <pattern> <task_id> [dry_run] [base_msg]
dev_kit_git_sync_process_group() {
  local group_name="$1"
  local pattern="$2"
  local task_id="${3:-unknown}"
  local dry_run="${4:-false}"
  local base_msg="${5:-}"
  
  local drift_file=".drift.tmp"
  local processed_file=".processed.tmp"
  
  [ -f "$drift_file" ] || { echo "Error: Drift file missing." >&2; return 1; }
  touch "$processed_file"

  local files=()
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! grep -Fqx "$f" "$processed_file" && echo "$f" | grep -Eq "$pattern"; then
      files+=("$f")
    fi
  done < "$drift_file"

  if [ ${#files[@]} -eq 0 ]; then
    return 0
  fi

  local commit_msg="${group_name}: resolve drift for $task_id"
  [ -n "$base_msg" ] && commit_msg="${group_name}: $base_msg ($task_id)"

  echo "Step: Grouping [$group_name] -> ${#files[@]} files"
  for f in "${files[@]}"; do
    echo "  + $f"
    echo "$f" >> "$processed_file"
  done

  if [ "$dry_run" = "true" ]; then
    echo "  [DRY-RUN] git add ${files[*]}"
    echo "  [DRY-RUN] git commit -m \"$commit_msg\""
  else
    if git add "${files[@]}" && git commit -m "$commit_msg"; then
      echo "  [OK] Committed group: $group_name"
    else
      echo "⚠️  [FAILOVER] Commit failed for group: $group_name"
      return 1
    fi
  fi
  echo ""
}

# Run the full git sync workflow
# Usage: dev_kit_git_sync_run [dry_run] [task_id] [message]
dev_kit_git_sync_run() {
  local dry_run="${1:-false}"
  local task_id="${2:-unknown}"
  local message="${3:-}"
  
  echo "--- dev.kit Git Sync: Starting Workflow ---"
  
  # Detect drift
  local staged unstaged untracked
  staged=$(git diff --name-only --cached)
  unstaged=$(git diff --name-only)
  untracked=$(git ls-files --others --exclude-standard)
  echo "$staged $unstaged $untracked" | tr ' ' '\n' | sort -u > .drift.tmp
  : > .processed.tmp

  # Define groups (Standard UDX grouping)
  local -a groups=(
    "docs:Group Documentation:^docs/|^README.md"
    "ai:Group AI & Integrations:^src/ai/|^.gemini/|^src/mappings/"
    "cli:Group CLI & Scripts:^bin/|^lib/|^src/cli/"
    "core:Group Core Infrastructure:^src/|^environment.yaml|^context7.json"
  )

  for group in "${groups[@]}"; do
    IFS=':' read -r id name pattern <<< "$group"
    echo "--- Step: $name ($id) ---"
    dev_kit_git_sync_process_group "$id" "$pattern" "$task_id" "$dry_run" "$message"
  done

  # Handle remaining drift
  local remaining=()
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! grep -Fqx "$f" .processed.tmp; then
      remaining+=("$f")
    fi
  done < .drift.tmp

  if [ ${#remaining[@]} -gt 0 ]; then
    echo "--- Step: Miscellaneous Drift ---"
    local commit_msg="misc: resolve remaining drift ($task_id)"
    if [ "$dry_run" = "true" ]; then
      echo "  [DRY-RUN] git add ${remaining[*]}"
      echo "  [DRY-RUN] git commit -m \"$commit_msg\""
    else
      git add "${remaining[@]}"
      git commit -m "$commit_msg"
      echo "  [OK] Committed remaining drift."
    fi
  fi

  rm -f .drift.tmp .processed.tmp
  echo "--- Git Sync Workflow Complete ---"
}
