#!/usr/bin/env bash

DEV_KIT_SYNC_DEFAULT_WORKFLOW="sync-git"
DEV_KIT_SYNC_DEFAULT_MODE="dev"
DEV_KIT_SYNC_BASE_BRANCH_NAMES="main master development staging trunk"
DEV_KIT_SYNC_BEHAVIOR="evaluation-only"

dev_kit_sync_mode_rank() {
  case "$1" in
    dev) printf "%s" "1" ;;
    ci) printf "%s" "2" ;;
    pr) printf "%s" "3" ;;
    *) printf "%s" "0" ;;
  esac
}

dev_kit_sync_mode_allows_step() {
  local mode="${1:-$DEV_KIT_SYNC_DEFAULT_MODE}"
  local min_mode="${2:-dev}"

  [ "$(dev_kit_sync_mode_rank "$mode")" -ge "$(dev_kit_sync_mode_rank "$min_mode")" ]
}

dev_kit_sync_has_git_repo() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1
}

dev_kit_sync_current_branch() {
  git -C "$1" branch --show-current 2>/dev/null || true
}

dev_kit_sync_nearest_base_branch() {
  local repo_dir="$1"
  local branch="$2"
  local candidate=""
  local candidate_ref=""
  local best_ref=""
  local best_name=""
  local best_distance=""
  local distance=""

  for candidate in $DEV_KIT_SYNC_BASE_BRANCH_NAMES; do
    if git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
      candidate_ref="origin/$candidate"
    elif git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$candidate"; then
      candidate_ref="$candidate"
    else
      continue
    fi

    if ! git -C "$repo_dir" merge-base --is-ancestor "$candidate_ref" "$branch" >/dev/null 2>&1; then
      continue
    fi

    distance="$(git -C "$repo_dir" rev-list --count "$candidate_ref..$branch" 2>/dev/null || printf "%s" "999999")"
    if [ -z "$best_ref" ] || [ "$distance" -lt "$best_distance" ]; then
      best_ref="$candidate_ref"
      best_name="$candidate"
      best_distance="$distance"
    fi
  done

  if [ -n "$best_name" ]; then
    printf "%s" "$best_name"
  fi
}

dev_kit_sync_default_branch() {
  local repo_dir="$1"
  local ref=""
  local branch=""
  local candidate=""
  local nearest_branch=""

  ref="$(git -C "$repo_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$ref" ]; then
    printf "%s" "${ref##*/}"
    return 0
  fi

  branch="$(dev_kit_sync_current_branch "$repo_dir")"
  for candidate in $DEV_KIT_SYNC_BASE_BRANCH_NAMES; do
    if [ "$branch" = "$candidate" ] && git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
      printf "%s" "$candidate"
      return 0
    fi
  done

  nearest_branch="$(dev_kit_sync_nearest_base_branch "$repo_dir" "$branch")"
  if [ -n "$nearest_branch" ]; then
    printf "%s" "$nearest_branch"
    return 0
  fi

  for candidate in $DEV_KIT_SYNC_BASE_BRANCH_NAMES; do
    if git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
      printf "%s" "$candidate"
      return 0
    fi
  done

  for candidate in $DEV_KIT_SYNC_BASE_BRANCH_NAMES; do
    if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$candidate"; then
      printf "%s" "$candidate"
      return 0
    fi
  done

  printf "%s" "main"
}

dev_kit_sync_upstream_branch() {
  git -C "$1" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true
}

dev_kit_sync_worktree_counts() {
  local repo_dir="$1"
  local staged=0
  local unstaged=0
  local untracked=0
  local line=""
  local xy=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    xy="${line:0:2}"
    if [ "${xy:0:1}" != " " ] && [ "${xy:0:1}" != "?" ]; then
      staged=$((staged + 1))
    fi
    if [ "${xy:1:1}" != " " ] && [ "${xy:1:1}" != "?" ]; then
      unstaged=$((unstaged + 1))
    fi
    if [ "$xy" = "??" ]; then
      untracked=$((untracked + 1))
    fi
  done <<EOF
$(git -C "$repo_dir" status --short 2>/dev/null || true)
EOF

  printf "%s|%s|%s" "$staged" "$unstaged" "$untracked"
}

dev_kit_sync_has_changes() {
  local repo_dir="$1"
  local counts=""
  local staged=0
  local unstaged=0
  local untracked=0

  counts="$(dev_kit_sync_worktree_counts "$repo_dir")"
  staged="${counts%%|*}"
  counts="${counts#*|}"
  unstaged="${counts%%|*}"
  untracked="${counts##*|}"

  [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ]
}

dev_kit_sync_can_run_gh() {
  command -v gh >/dev/null 2>&1
}

dev_kit_sync_gh_auth_state() {
  if ! dev_kit_sync_can_run_gh; then
    printf "%s" "missing"
    return 0
  fi

  if gh auth status >/dev/null 2>&1; then
    printf "%s" "available"
    return 0
  fi

  printf "%s" "unauthenticated"
}

dev_kit_sync_remote_state() {
  if git -C "$1" remote get-url origin >/dev/null 2>&1; then
    printf "%s" "available"
    return 0
  fi

  printf "%s" "missing"
}

dev_kit_sync_repo_supports_release_metadata() {
  local repo_dir="$1"

  [ -f "$repo_dir/package.json" ] || [ -f "$repo_dir/composer.json" ] || [ -f "$repo_dir/CHANGELOG.md" ] || [ -f "$repo_dir/changelog.md" ]
}

dev_kit_sync_pr_template_state() {
  local repo_dir="$1"

  if [ -f "$repo_dir/.github/pull_request_template.md" ] || \
     [ -f "$repo_dir/.github/PULL_REQUEST_TEMPLATE.md" ] || \
     [ -d "$repo_dir/.github/PULL_REQUEST_TEMPLATE" ]; then
    printf "%s" "repo-template"
    return 0
  fi

  printf "%s" "dev-kit-template"
}

dev_kit_sync_capability_lines() {
  local repo_dir="$1"

  printf "%s|%s\n" "git" "available"

  if dev_kit_sync_can_run_gh; then
    printf "%s|%s\n" "gh" "available"
  else
    printf "%s|%s\n" "gh" "missing"
  fi

  printf "%s|%s\n" "github_auth" "$(dev_kit_sync_gh_auth_state)"
  printf "%s|%s\n" "remote" "$(dev_kit_sync_remote_state "$repo_dir")"
}

dev_kit_sync_step_state() {
  local repo_dir="$1"
  local step_id="$2"
  local mode="${3:-$DEV_KIT_SYNC_DEFAULT_MODE}"
  local branch=""
  local upstream=""
  local default_branch=""
  local counts=""
  local staged=0
  local unstaged=0
  local untracked=0
  local gh_state=""

  branch="$(dev_kit_sync_current_branch "$repo_dir")"
  upstream="$(dev_kit_sync_upstream_branch "$repo_dir")"
  default_branch="$(dev_kit_sync_default_branch "$repo_dir")"
  counts="$(dev_kit_sync_worktree_counts "$repo_dir")"
  staged="${counts%%|*}"
  counts="${counts#*|}"
  unstaged="${counts%%|*}"
  untracked="${counts##*|}"
  gh_state="$(dev_kit_sync_gh_auth_state)"

  case "$step_id" in
    worktree_status)
      printf "done|%s staged, %s unstaged, %s untracked" "$staged" "$unstaged" "$untracked"
      ;;
    change_analysis)
      if dev_kit_sync_has_changes "$repo_dir"; then
        printf "%s" "done|Local changes exist and should be grouped into logical commits"
      else
        printf "%s" "done|No local changes detected; treat this as a new session branch review"
      fi
      ;;
    branch_analysis)
      if [ -z "$branch" ]; then
        printf "%s" "blocked|Current branch could not be detected"
      elif [ "$branch" = "$default_branch" ] && [ -n "$upstream" ]; then
        printf "done|Current branch %s is the tracked base branch for this repo" "$branch"
      elif [ -n "$upstream" ]; then
        printf "done|Current branch %s tracks %s and should be compared against %s" "$branch" "$upstream" "$default_branch"
      else
        printf "pending|Current branch %s has no upstream; compare it against %s before pushing" "$branch" "$default_branch"
      fi
      ;;
    logical_commits)
      if dev_kit_sync_has_changes "$repo_dir"; then
        printf "%s" "pending|Review changed files and split work into logical commits"
      else
        printf "%s" "skipped|No local changes to group into commits"
      fi
      ;;
    release_metadata)
      if dev_kit_sync_repo_supports_release_metadata "$repo_dir"; then
        printf "%s" "pending|Version and changelog files exist; update them if the repo release model requires it"
      else
        printf "%s" "skipped|No version or changelog contract detected"
      fi
      ;;
    branch_prepare)
      if [ -z "$branch" ]; then
        printf "%s" "blocked|Cannot create or validate a feature branch until git reports the current branch"
      elif [ "$branch" = "$default_branch" ] && ! dev_kit_sync_has_changes "$repo_dir"; then
        printf "done|Current branch %s is the base branch and no shareable work is pending" "$default_branch"
      elif [ "$branch" = "$default_branch" ]; then
        printf "pending|Current branch %s is the base branch; keep working locally or create a feature branch before push or pull request work" "$default_branch"
      else
        printf "done|Current branch %s is ready for feature work review" "$branch"
      fi
      ;;
    remote_push)
      if ! dev_kit_sync_mode_allows_step "$mode" "ci"; then
        printf "%s" "skipped|Dev mode stops before remote push"
        return 0
      fi
      if [ "$(dev_kit_sync_remote_state "$repo_dir")" != "available" ]; then
        printf "%s" "blocked|origin remote is missing"
      elif [ -n "$upstream" ]; then
        printf "done|Branch tracks %s and can be pushed with follow-up changes" "$upstream"
      else
        printf "%s" "pending|Push the current branch and set an upstream"
      fi
      ;;
    pr_prepare)
      if ! dev_kit_sync_mode_allows_step "$mode" "ci"; then
        printf "%s" "skipped|Dev mode does not prepare a pull request yet"
        return 0
      fi
      if ! dev_kit_sync_mode_allows_step "$mode" "pr"; then
        printf "%s" "skipped|CI mode stops after push and does not prepare a pull request"
        return 0
      fi
      if [ "$(dev_kit_sync_remote_state "$repo_dir")" != "available" ]; then
        printf "%s" "blocked|A remote is required before preparing a pull request"
      else
        printf "pending|Use %s for the pull request description" "$(dev_kit_sync_pr_template_state "$repo_dir")"
      fi
      ;;
    pr_create)
      if ! dev_kit_sync_mode_allows_step "$mode" "ci"; then
        printf "%s" "skipped|Dev mode does not create a pull request"
        return 0
      fi
      if ! dev_kit_sync_mode_allows_step "$mode" "pr"; then
        printf "%s" "skipped|CI mode does not create a pull request"
        return 0
      fi
      if [ "$gh_state" = "missing" ]; then
        printf "%s" "blocked|gh CLI is not installed"
      elif [ "$gh_state" = "unauthenticated" ]; then
        printf "%s" "blocked|gh CLI is installed but not authenticated"
      elif [ "$(dev_kit_sync_remote_state "$repo_dir")" != "available" ]; then
        printf "%s" "blocked|A remote is required before creating a pull request"
      else
        printf "%s" "pending|gh is available; create the pull request after push and description review"
      fi
      ;;
    actions_verify)
      if ! dev_kit_sync_mode_allows_step "$mode" "pr"; then
        printf "%s" "skipped|Workflow verification is reserved for pr mode after pull request creation"
        return 0
      fi
      if [ "$gh_state" = "available" ]; then
        printf "%s" "pending|Verify related GitHub Actions after the pull request exists"
      else
        printf "%s" "skipped|GitHub CLI or auth is unavailable, so workflow verification cannot be checked automatically"
      fi
      ;;
    *)
      printf "%s" "blocked|Unsupported sync step"
      ;;
  esac
}

dev_kit_sync_step_lines() {
  local repo_dir="$1"
  local workflow_id="${2:-$DEV_KIT_SYNC_DEFAULT_WORKFLOW}"
  local mode="${3:-$DEV_KIT_SYNC_DEFAULT_MODE}"
  local step_line=""
  local step_id=""
  local step_label=""
  local step_check=""
  local step_min_mode=""
  local step_execution=""
  local step_optional=""
  local state_line=""
  local status=""
  local summary=""

  while IFS= read -r step_line; do
    [ -n "$step_line" ] || continue
    step_id="${step_line%%|*}"
    step_line="${step_line#*|}"
    step_label="${step_line%%|*}"
    step_line="${step_line#*|}"
    step_check="${step_line%%|*}"
    step_line="${step_line#*|}"
    step_min_mode="${step_line%%|*}"
    step_line="${step_line#*|}"
    step_execution="${step_line%%|*}"
    step_optional="${step_line##*|}"
    if ! dev_kit_sync_mode_allows_step "$mode" "$step_min_mode"; then
      continue
    fi
    state_line="$(dev_kit_sync_step_state "$repo_dir" "$step_id" "$mode")"
    status="${state_line%%|*}"
    summary="${state_line#*|}"
    printf "%s|%s|%s|%s|%s\n" "$step_id" "$step_label" "$step_execution" "$status" "$summary"
  done <<EOF
$(dev_kit_workflow_step_lines "$workflow_id")
EOF
}

dev_kit_sync_steps_json() {
  local repo_dir="$1"
  local workflow_id="${2:-$DEV_KIT_SYNC_DEFAULT_WORKFLOW}"
  local mode="${3:-$DEV_KIT_SYNC_DEFAULT_MODE}"
  local first=1
  local line=""
  local step_id=""
  local step_label=""
  local execution=""
  local status=""
  local summary=""

  printf "["
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    step_id="${line%%|*}"
    line="${line#*|}"
    step_label="${line%%|*}"
    line="${line#*|}"
    execution="${line%%|*}"
    line="${line#*|}"
    status="${line%%|*}"
    summary="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    printf '\n    { "id": "%s", "label": "%s", "execution": "%s", "status": "%s", "summary": "%s" }' \
      "$step_id" "$step_label" "$execution" "$status" "$(dev_kit_json_escape "$summary")"
    first=0
  done <<EOF
$(dev_kit_sync_step_lines "$repo_dir" "$workflow_id" "$mode")
EOF
  if [ "$first" -eq 0 ]; then
    printf '\n  '
  fi
  printf "]"
}

dev_kit_sync_capabilities_json() {
  local repo_dir="$1"
  local first=1
  local line=""
  local name=""
  local status=""

  printf "{"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    name="${line%%|*}"
    status="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    printf '\n    "%s": "%s"' "$name" "$status"
    first=0
  done <<EOF
$(dev_kit_sync_capability_lines "$repo_dir")
EOF
  if [ "$first" -eq 0 ]; then
    printf '\n  '
  fi
  printf "}"
}

dev_kit_sync_capabilities_text() {
  local repo_dir="$1"
  local line=""
  local name=""
  local status=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    name="${line%%|*}"
    status="${line#*|}"
    printf '  - %s: %s\n' "$name" "$status"
  done <<EOF
$(dev_kit_sync_capability_lines "$repo_dir")
EOF
}

dev_kit_sync_steps_text() {
  local repo_dir="$1"
  local workflow_id="${2:-$DEV_KIT_SYNC_DEFAULT_WORKFLOW}"
  local mode="${3:-$DEV_KIT_SYNC_DEFAULT_MODE}"
  local line=""
  local step_id=""
  local step_label=""
  local execution=""
  local status=""
  local summary=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    step_id="${line%%|*}"
    line="${line#*|}"
    step_label="${line%%|*}"
    line="${line#*|}"
    execution="${line%%|*}"
    line="${line#*|}"
    status="${line%%|*}"
    summary="${line#*|}"
    printf '  - %s: %s\n' "$step_id" "$status"
    printf '    label: %s\n' "$step_label"
    printf '    execution: %s\n' "$execution"
    printf '    summary: %s\n' "$summary"
  done <<EOF
$(dev_kit_sync_step_lines "$repo_dir" "$workflow_id" "$mode")
EOF
}
