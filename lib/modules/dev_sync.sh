#!/usr/bin/env bash

DEV_KIT_SYNC_GH_AUTH_STATE_CACHE=""
DEV_KIT_SYNC_GH_AUTH_STATE_CACHE_READY=0

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

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    [ "$candidate" = "$branch" ] && continue  # never pick the current branch as its own base
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
  done <<EOF
$(dev_kit_sync_base_branch_names)
EOF

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
  nearest_branch="$(dev_kit_sync_nearest_base_branch "$repo_dir" "$branch")"
  if [ -n "$nearest_branch" ]; then
    printf "%s" "$nearest_branch"
    return 0
  fi

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    if git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
      printf "%s" "$candidate"
      return 0
    fi
  done <<EOF
$(dev_kit_sync_base_branch_names)
EOF

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$candidate"; then
      printf "%s" "$candidate"
      return 0
    fi
  done <<EOF
$(dev_kit_sync_base_branch_names)
EOF

  printf "%s" "latest"
}

dev_kit_sync_upstream_branch() {
  git -C "$1" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true
}

dev_kit_sync_ahead_behind() {
  local repo_dir="$1"
  local upstream=""
  local counts=""

  upstream="$(dev_kit_sync_upstream_branch "$repo_dir")"
  if [ -z "$upstream" ]; then
    printf "%s|%s" "0" "0"
    return 0
  fi

  counts="$(git -C "$repo_dir" rev-list --left-right --count "$upstream...HEAD" 2>/dev/null || true)"
  if [ -z "$counts" ]; then
    printf "%s|%s" "0" "0"
    return 0
  fi

  printf "%s|%s" "$(printf "%s" "$counts" | awk '{print $1}')" "$(printf "%s" "$counts" | awk '{print $2}')"
}

dev_kit_sync_branch_role() {
  local repo_dir="$1"
  local branch=""
  local default_branch=""

  branch="$(dev_kit_sync_current_branch "$repo_dir")"
  default_branch="$(dev_kit_sync_default_branch "$repo_dir")"

  if [ "$branch" = "$default_branch" ]; then
    printf "%s" "$(dev_kit_sync_branch_role_base)"
    return 0
  fi

  printf "%s" "$(dev_kit_sync_branch_role_feature)"
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
  if [ "$DEV_KIT_SYNC_GH_AUTH_STATE_CACHE_READY" -eq 1 ]; then
    printf "%s" "$DEV_KIT_SYNC_GH_AUTH_STATE_CACHE"
    return 0
  fi

  if ! dev_kit_sync_can_run_gh; then
    DEV_KIT_SYNC_GH_AUTH_STATE_CACHE="missing"
    DEV_KIT_SYNC_GH_AUTH_STATE_CACHE_READY=1
    printf "%s" "missing"
    return 0
  fi

  if GH_PROMPT_DISABLED=1 gh auth status >/dev/null 2>&1; then
    DEV_KIT_SYNC_GH_AUTH_STATE_CACHE="available"
    DEV_KIT_SYNC_GH_AUTH_STATE_CACHE_READY=1
    printf "%s" "available"
    return 0
  fi

  DEV_KIT_SYNC_GH_AUTH_STATE_CACHE="unauthenticated"
  DEV_KIT_SYNC_GH_AUTH_STATE_CACHE_READY=1
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

dev_kit_sync_repo_hooks_dir() {
  local repo_dir="$1"
  local hooks_path=""

  hooks_path="$(git -C "$repo_dir" config --get core.hooksPath 2>/dev/null || true)"
  if [ -n "$hooks_path" ]; then
    printf "%s" "$hooks_path"
    return 0
  fi

  if [ -d "$repo_dir/$(dev_kit_sync_default_hooks_dir)" ]; then
    printf "%s" "$(dev_kit_sync_default_hooks_dir)"
    return 0
  fi

  printf "%s" ".git/hooks"
}

dev_kit_sync_hook_file() {
  local repo_dir="$1"
  local hook_name="$2"
  local hooks_dir=""

  hooks_dir="$(dev_kit_sync_repo_hooks_dir "$repo_dir")"
  printf "%s/%s" "$repo_dir/$hooks_dir" "$hook_name"
}

dev_kit_sync_hook_summary() {
  local repo_dir="$1"
  local hook_name="$2"
  local hook_file=""
  local summary=""

  hook_file="$(dev_kit_sync_hook_file "$repo_dir" "$hook_name")"
  if [ ! -f "$hook_file" ]; then
    printf "%s|%s" "missing" "No $hook_name hook detected"
    return 0
  fi

  if [ "$hook_name" = "pre-push" ] && rg -n "bash tests/run.sh" "$hook_file" >/dev/null 2>&1; then
    printf "%s|%s" "present" "Runs bash tests/run.sh before push"
    return 0
  fi

  printf "%s|%s" "present" "Hook exists at $(basename "$hook_file")"
}

dev_kit_sync_hook_recommendation() {
  local repo_dir="$1"
  local hook_name="$2"
  local hook_file=""

  hook_file="$(dev_kit_sync_hook_file "$repo_dir" "$hook_name")"
  if [ ! -f "$hook_file" ]; then
    printf "%s" "No hook-specific preparation detected."
    return 0
  fi

  if [ "$hook_name" = "pre-push" ] && rg -n "bash tests/run.sh" "$hook_file" >/dev/null 2>&1; then
    printf "%s" "Before push, make sure the local verification runtime is ready for bash tests/run.sh."
    return 0
  fi

  printf "%s" "Review the configured hook before running the related git action."
}

dev_kit_sync_hooks_lines() {
  local repo_dir="$1"
  local hook_name=""
  local state_summary=""
  local state=""
  local summary=""
  local recommendation=""

  for hook_name in pre-commit commit-msg pre-push; do
    state_summary="$(dev_kit_sync_hook_summary "$repo_dir" "$hook_name")"
    state="${state_summary%%|*}"
    summary="${state_summary#*|}"
    recommendation="$(dev_kit_sync_hook_recommendation "$repo_dir" "$hook_name")"
    printf "%s|%s|%s|%s\n" "$hook_name" "$state" "$summary" "$recommendation"
  done
}

dev_kit_sync_hooks_text() {
  local repo_dir="$1"
  local line=""
  local hook_name=""
  local state=""
  local summary=""
  local recommendation=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    hook_name="${line%%|*}"
    line="${line#*|}"
    state="${line%%|*}"
    line="${line#*|}"
    summary="${line%%|*}"
    recommendation="${line#*|}"
    printf '  - %s: %s\n' "$hook_name" "$state"
    printf '    summary: %s\n' "$summary"
    printf '    recommendation: %s\n' "$recommendation"
  done <<EOF
$(dev_kit_sync_hooks_lines "$repo_dir")
EOF
}

dev_kit_sync_hooks_focus_text() {
  local repo_dir="$1"
  local line=""
  local hook_name=""
  local state=""
  local summary=""
  local recommendation=""
  local matched=0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    hook_name="${line%%|*}"
    line="${line#*|}"
    state="${line%%|*}"
    line="${line#*|}"
    summary="${line%%|*}"
    recommendation="${line#*|}"
    if [ "$state" = "present" ]; then
      printf '  - %s: %s\n' "$hook_name" "$summary"
      printf '    recommendation: %s\n' "$recommendation"
      matched=1
    fi
  done <<EOF
$(dev_kit_sync_hooks_lines "$repo_dir")
EOF

  if [ "$matched" -eq 0 ]; then
    printf '  - none detected\n'
  fi
}

dev_kit_sync_hooks_json() {
  local repo_dir="$1"
  local first=1
  local line=""
  local hook_name=""
  local state=""
  local summary=""
  local recommendation=""

  printf "["
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    hook_name="${line%%|*}"
    line="${line#*|}"
    state="${line%%|*}"
    line="${line#*|}"
    summary="${line%%|*}"
    recommendation="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    printf '\n    { "id": "%s", "state": "%s", "summary": "%s", "recommendation": "%s" }' \
      "$hook_name" "$state" "$(dev_kit_json_escape "$summary")" "$(dev_kit_json_escape "$recommendation")"
    first=0
  done <<EOF
$(dev_kit_sync_hooks_lines "$repo_dir")
EOF
  if [ "$first" -eq 0 ]; then
    printf '\n  '
  fi
  printf "]"
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

dev_kit_sync_repo_state_lines() {
  local repo_dir="$1"
  local branch=""
  local branch_role=""
  local default_branch=""
  local upstream=""
  local counts=""
  local staged=0
  local unstaged=0
  local untracked=0
  local ahead_behind=""
  local behind=0
  local ahead=0
  local worktree="clean"

  branch="$(dev_kit_sync_current_branch "$repo_dir")"
  branch_role="$(dev_kit_sync_branch_role "$repo_dir")"
  default_branch="$(dev_kit_sync_default_branch "$repo_dir")"
  upstream="$(dev_kit_sync_upstream_branch "$repo_dir")"
  counts="$(dev_kit_sync_worktree_counts "$repo_dir")"
  staged="${counts%%|*}"
  counts="${counts#*|}"
  unstaged="${counts%%|*}"
  untracked="${counts##*|}"
  ahead_behind="$(dev_kit_sync_ahead_behind "$repo_dir")"
  behind="${ahead_behind%%|*}"
  ahead="${ahead_behind##*|}"

  if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
    worktree="dirty"
  fi

  printf "%s|%s\n" "branch" "$branch"
  printf "%s|%s\n" "branch_role" "$branch_role"
  printf "%s|%s\n" "base_branch" "$default_branch"
  printf "%s|%s\n" "upstream" "${upstream:-none}"
  printf "%s|%s\n" "ahead" "$ahead"
  printf "%s|%s\n" "behind" "$behind"
  printf "%s|%s\n" "worktree" "$worktree"
  printf "%s|%s\n" "staged" "$staged"
  printf "%s|%s\n" "unstaged" "$unstaged"
  printf "%s|%s\n" "untracked" "$untracked"
}

dev_kit_sync_repo_state_text() {
  local repo_dir="$1"
  local line=""
  local key=""
  local value=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    key="${line%%|*}"
    value="${line#*|}"
    printf '  - %s: %s\n' "$key" "$value"
  done <<EOF
$(dev_kit_sync_repo_state_lines "$repo_dir")
EOF
}

dev_kit_sync_repo_state_compact_text() {
  local repo_dir="$1"
  local branch=""
  local branch_role=""
  local base_branch=""
  local upstream=""
  local ahead_behind=""
  local behind=0
  local ahead=0
  local counts=""
  local staged=0
  local unstaged=0
  local untracked=0
  local worktree="clean"

  branch="$(dev_kit_sync_current_branch "$repo_dir")"
  branch_role="$(dev_kit_sync_branch_role "$repo_dir")"
  base_branch="$(dev_kit_sync_default_branch "$repo_dir")"
  upstream="$(dev_kit_sync_upstream_branch "$repo_dir")"
  ahead_behind="$(dev_kit_sync_ahead_behind "$repo_dir")"
  behind="${ahead_behind%%|*}"
  ahead="${ahead_behind##*|}"
  counts="$(dev_kit_sync_worktree_counts "$repo_dir")"
  staged="${counts%%|*}"
  counts="${counts#*|}"
  unstaged="${counts%%|*}"
  untracked="${counts##*|}"

  if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
    worktree="dirty"
  fi

  printf '  - branch: %s (%s)\n' "$branch" "$branch_role"
  printf '  - base: %s\n' "$base_branch"
  printf '  - upstream: %s\n' "${upstream:-none}"
  printf '  - sync: ahead %s, behind %s\n' "$ahead" "$behind"
  if [ "$worktree" = "clean" ]; then
    printf '  - worktree: clean\n'
  else
    printf '  - worktree: dirty (%s staged, %s unstaged, %s untracked)\n' "$staged" "$unstaged" "$untracked"
  fi
}

dev_kit_sync_repo_state_json() {
  local repo_dir="$1"
  local first=1
  local line=""
  local key=""
  local value=""

  printf "{"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    key="${line%%|*}"
    value="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    case "$key" in
      ahead|behind|staged|unstaged|untracked)
        printf '\n    "%s": %s' "$key" "$value"
        ;;
      *)
        printf '\n    "%s": "%s"' "$key" "$(dev_kit_json_escape "$value")"
        ;;
    esac
    first=0
  done <<EOF
$(dev_kit_sync_repo_state_lines "$repo_dir")
EOF
  if [ "$first" -eq 0 ]; then
    printf '\n  '
  fi
  printf "}"
}

dev_kit_sync_next_hint() {
  local repo_dir="$1"
  local branch=""
  local default_branch=""
  local upstream=""
  local branch_role=""

  branch="$(dev_kit_sync_current_branch "$repo_dir")"
  default_branch="$(dev_kit_sync_default_branch "$repo_dir")"
  upstream="$(dev_kit_sync_upstream_branch "$repo_dir")"
  branch_role="$(dev_kit_sync_branch_role "$repo_dir")"

  if dev_kit_sync_has_changes "$repo_dir"; then
    if [ "$branch_role" = "$(dev_kit_sync_branch_role_base)" ]; then
      printf "%s" "You have local changes on the base branch. Keep iterating locally or move them onto a feature branch before push or PR work."
      return 0
    fi
    printf "%s" "You have local changes on a feature branch. Group them into logical commits before push or PR work."
    return 0
  fi

  if [ "$branch_role" = "$(dev_kit_sync_branch_role_base)" ]; then
    printf "%s" "Base branch is clean. No immediate sync action is required."
    return 0
  fi

  if [ -z "$upstream" ]; then
    printf "Feature branch %s is clean but has no upstream. Push it when you want to share work." "$branch"
    return 0
  fi

  printf "Feature branch %s is clean and tracks %s. Choose whether to keep iterating, open a PR, or verify CI state." "$branch" "$upstream"
}

dev_kit_sync_issue_hint() {
  local repo_dir="$1"
  local gh_state=""

  if [ "$(dev_kit_sync_remote_state "$repo_dir")" != "available" ]; then
    printf "%s" "No origin remote detected, so related GitHub issues cannot be checked from this repo."
    return 0
  fi

  gh_state="$(dev_kit_sync_gh_auth_state)"
  case "$gh_state" in
    available)
      printf "%s" "Check related issues with gh issue list --assignee @me --state open --limit 10."
      ;;
    unauthenticated)
      printf "%s" "gh is installed but not authenticated; sign in before checking related assigned issues."
      ;;
    *)
      printf "%s" "Install gh if you want assigned issue and pull request context from GitHub."
      ;;
  esac
}

dev_kit_sync_start_here_text() {
  local repo_dir="$1"
  local branch=""
  local default_branch=""
  local upstream=""
  local branch_role=""

  branch="$(dev_kit_sync_current_branch "$repo_dir")"
  default_branch="$(dev_kit_sync_default_branch "$repo_dir")"
  upstream="$(dev_kit_sync_upstream_branch "$repo_dir")"
  branch_role="$(dev_kit_sync_branch_role "$repo_dir")"

  printf 'Inspect git status and worktree shape first.\n'

  if [ -n "$branch" ]; then
    printf 'Compare current branch %s against base branch %s.\n' "$branch" "$default_branch"
  else
    printf 'Confirm the current branch and base branch before making changes.\n'
  fi

  if [ "$(dev_kit_sync_remote_state "$repo_dir")" = "available" ]; then
    printf 'Refresh remote state with git fetch origin --prune before branch or PR decisions.\n'
  else
    printf 'Add or verify the origin remote before planning push or PR work.\n'
  fi

  if [ "$branch_role" = "$(dev_kit_sync_branch_role_feature)" ] && [ -n "$upstream" ]; then
    printf 'Review what is ahead of %s before adding more work.\n' "$default_branch"
  elif [ "$branch_role" = "$(dev_kit_sync_branch_role_feature)" ]; then
    printf 'Review branch diff against %s before pushing a new upstream.\n' "$default_branch"
  else
    printf 'If new shareable work is starting from %s, move it onto a feature branch.\n' "$default_branch"
  fi

  printf '%s\n' "$(dev_kit_sync_issue_hint "$repo_dir")"
}

dev_kit_sync_start_here_json() {
  dev_kit_sync_start_here_text "$1" | dev_kit_lines_to_json_array
}

dev_kit_sync_step_state() {
  local repo_dir="$1"
  local step_id="$2"
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
      if [ "$(dev_kit_sync_remote_state "$repo_dir")" != "available" ]; then
        printf "%s" "blocked|origin remote is missing"
      elif [ -n "$upstream" ]; then
        printf "done|Branch tracks %s and can be pushed with follow-up changes" "$upstream"
      else
        printf "%s" "pending|Push the current branch and set an upstream"
      fi
      ;;
    pr_prepare)
      if [ "$(dev_kit_sync_remote_state "$repo_dir")" != "available" ]; then
        printf "%s" "blocked|A remote is required before preparing a pull request"
      else
        printf "pending|Use %s for the pull request description" "$(dev_kit_sync_pr_template_state "$repo_dir")"
      fi
      ;;
    pr_create)
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
  local workflow_id="${2:-$(dev_kit_sync_default_workflow)}"
  local step_line=""
  local step_id=""
  local step_label=""
  local step_check=""
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
    state_line="$(dev_kit_sync_step_state "$repo_dir" "$step_id")"
    status="${state_line%%|*}"
    summary="${state_line#*|}"
    printf "%s|%s|%s|%s\n" "$step_id" "$step_label" "$status" "$summary"
  done <<EOF
$(dev_kit_workflow_step_lines "$workflow_id")
EOF
}

dev_kit_sync_steps_json() {
  local repo_dir="$1"
  local workflow_id="${2:-$(dev_kit_sync_default_workflow)}"
  local first=1
  local line=""
  local step_id=""
  local step_label=""
  local status=""
  local summary=""

  printf "["
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    step_id="${line%%|*}"
    line="${line#*|}"
    step_label="${line%%|*}"
    line="${line#*|}"
    status="${line%%|*}"
    summary="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    printf '\n    { "id": "%s", "label": "%s", "status": "%s", "summary": "%s" }' \
      "$step_id" "$step_label" "$status" "$(dev_kit_json_escape "$summary")"
    first=0
  done <<EOF
$(dev_kit_sync_step_lines "$repo_dir" "$workflow_id")
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

dev_kit_sync_capability_warnings_text() {
  local repo_dir="$1"
  local line=""
  local name=""
  local status=""
  local matched=0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    name="${line%%|*}"
    status="${line#*|}"
    if [ "$status" = "available" ]; then
      continue
    fi
    printf '  - %s: %s\n' "$name" "$status"
    matched=1
  done <<EOF
$(dev_kit_sync_capability_lines "$repo_dir")
EOF

  if [ "$matched" -eq 0 ]; then
    printf '  - all required capabilities look available\n'
  fi
}

dev_kit_sync_steps_text() {
  local repo_dir="$1"
  local workflow_id="${2:-$(dev_kit_sync_default_workflow)}"
  local max_steps="${3:-$(dev_kit_sync_text_max_next_steps)}"
  local line=""
  local step_id=""
  local step_label=""
  local status=""
  local summary=""
  local printed=0
  local total=0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    step_id="${line%%|*}"
    line="${line#*|}"
    step_label="${line%%|*}"
    line="${line#*|}"
    status="${line%%|*}"
    summary="${line#*|}"
    total=$((total + 1))
    case "$status" in
      done|skipped)
        continue
        ;;
    esac
    if [ "$printed" -lt "$max_steps" ]; then
      printf '  - %s: %s\n' "$step_label" "$summary"
      printed=$((printed + 1))
    fi
  done <<EOF
$(dev_kit_sync_step_lines "$repo_dir" "$workflow_id")
EOF

  if [ "$printed" -eq 0 ]; then
    printf '  - no immediate workflow actions\n'
    return 0
  fi

  if [ "$total" -gt "$printed" ]; then
    printf '  - additional workflow detail is available in --json output\n'
  fi
}
