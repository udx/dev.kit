#!/usr/bin/env bash

# dev.kit Sync Command
# Unified entry point for programmatic repository synchronization.

dev_kit_cmd_sync() {
  local dry_run="false"
  local task_id="unknown"
  local message=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run="true"; shift ;;
      --task-id) task_id="$2"; shift 2 ;;
      --message) message="$2"; shift 2 ;;
      -h|--help)
        cat <<'SYNC_HELP'
Usage: dev.kit sync [options]

Options:
  --dry-run      Show what commits would be made without executing them
  --task-id <id> The current task ID to associate with commits
  --message <m>  Optional base message prefix
  -h, --help     Show this help message

Example:
  dev.kit sync --dry-run
  dev.kit sync --task-id "TASK-123" --message "feat: implementation"
SYNC_HELP
        return 0
        ;;
      *) echo "Unknown option: $1"; return 1 ;;
    esac
  done

  if command -v dev_kit_git_sync_run >/dev/null 2>&1; then
    dev_kit_git_sync_run "$dry_run" "$task_id" "$message"
  else
    echo "Error: Git sync module not loaded." >&2
    return 1
  fi
}
