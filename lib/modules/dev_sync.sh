#!/usr/bin/env bash

DEV_KIT_SYNC_GH_AUTH_STATE_CACHE=""
DEV_KIT_SYNC_GH_AUTH_STATE_CACHE_READY=0

dev_kit_sync_branch_role_base() {
  printf '%s' 'base'
}

dev_kit_sync_branch_role_feature() {
  printf '%s' 'feature'
}

dev_kit_sync_base_branch_names() {
  cat <<'EOF'
latest
main
master
development
staging
trunk
EOF
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
