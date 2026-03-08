#!/usr/bin/env bash

# dev.kit Git Sync Module
# Core logic for logical, atomic repository synchronization and drift resolution.

# Prepare the repository for work (Pre-flight checks)
# Usage: dev_kit_git_sync_prepare [target_branch]
dev_kit_git_sync_prepare() {
  local target_main="${1:-main}"
  
  echo "--- dev.kit Git Sync: Pre-work Preparation ---"
  
  # 1. Detect current branch
  local current_branch
  current_branch=$(git branch --show-current)
  echo "✔ Current branch: $current_branch"
  
  # 2. Check for origin updates
  echo "Checking origin/$target_main for updates..."
  git fetch origin "$target_main" --quiet
  
  local behind
  behind=$(git rev-list HEAD..origin/"$target_main" --count)
  if [ "$behind" -gt 0 ]; then
    echo "⚠ Your branch is behind origin/$target_main by $behind commits."
    printf "Would you like to merge origin/$target_main into $current_branch? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      if git merge origin/"$target_main"; then
        echo "✔ Merged latest $target_main into $current_branch."
      else
        echo "❌ Merge conflict detected. Please resolve manually."
        return 1
      fi
    fi
  else
    echo "✔ Your branch is up-to-date with origin/$target_main."
  fi
  
  # 3. Ask if new branch is needed
  printf "Would you like to create a new branch for this work? (y/N): "
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    printf "Enter new branch name: "
    read -r new_branch
    if [ -n "$new_branch" ]; then
      if git checkout -b "$new_branch"; then
        echo "✔ Switched to new branch: $new_branch"
      else
        echo "❌ Failed to create branch $new_branch."
        return 1
      fi
    fi
  fi
  
  echo "--- Preparation Complete ---"
  return 0
}

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
  
  # Resolve target main branch
  local target_main="main"
  if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
    if git rev-parse --verify origin/master >/dev/null 2>&1; then
      target_main="master"
    fi
  fi

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

  # 5. Proactive PR Suggestion (New)
  if [ "$dry_run" = "false" ] && command -v dev_kit_github_health >/dev/null 2>&1; then
    if dev_kit_github_health >/dev/null 2>&1; then
      local current_branch; current_branch=$(git branch --show-current)
      # Don't suggest PR for the default main branch
      if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        echo ""
        printf "✔ Synchronization complete. Would you like to create a Pull Request for $current_branch? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
          local pr_title="feat: resolve $task_id"
          [ -n "$message" ] && pr_title="$message"
          
          # Generate a brief summary from the git diff (stat only for brevity)
          local diff_summary=""
          if git rev-parse --verify origin/"$target_main" >/dev/null 2>&1; then
            diff_summary=$(git diff origin/"$target_main"...HEAD --stat | head -n 20)
          else
            # Fallback if origin is not available
            diff_summary="Changes since common ancestor could not be calculated (origin missing)."
          fi
          
          local pr_body="### 🚀 Drift Resolution: $task_id\n\n$message\n\n#### 📊 Change Summary\n\`\`\`text\n$diff_summary\n\`\`\`\n\nAutomated via \`dev.kit sync\`."
          
          if dev_kit_github_pr_create "$pr_title" "$pr_body" "$target_main"; then
             echo "✔ Pull Request synchronized successfully."
          else
             echo "❌ Failed to synchronize Pull Request."
          fi
        fi
      fi
    fi
  fi
}
