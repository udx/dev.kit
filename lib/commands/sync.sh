#!/usr/bin/env bash

# @description: Resolve repository drift or prepare for new work.
# @intent: sync, commit, drift, atomic, push, resolve, prepare, branch
# @objective: Maintain high-fidelity repository state by either preparing the environment for work (branch management, origin sync) or resolving drift via logical, domain-specific commits.
# @usage: dev.kit sync prepare [main_branch]
# @usage: dev.kit sync run --task-id "TASK-123" --message "feat: implementation"
# @usage: dev.kit sync --dry-run
# @workflow: 1. (Prepare) Detect Branch -> 2. (Prepare) Sync Origin -> 3. (Run) Group Changes -> 4. (Run) Atomic Commits

dev_kit_cmd_sync() {
  local sub="${1:-run}"
  
  case "$sub" in
    prepare)
      local target_main="${2:-main}"
      if command -v dev_kit_git_sync_prepare >/dev/null 2>&1; then
        dev_kit_git_sync_prepare "$target_main"
      else
        echo "Error: Git sync module not loaded." >&2
        return 1
      fi
      ;;
    reminder)
      if command -v ui_sync_reminder >/dev/null 2>&1; then
        ui_sync_reminder
      else
        echo "Error: UI module not loaded." >&2
        return 1
      fi
      ;;
    run|execute|*)
      # If first arg isn't a known subcommand, treat as 'run' and don't shift if it looks like an option
      if [[ "$sub" == --* ]]; then
        # It's an option, so we are in 'run' mode by default
        sub="run"
      else
        shift 1
      fi

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
Usage: dev.kit sync <command> [options]

Commands:
  prepare [main]  Prepare repository (fetch origin, merge, optional branch)
  run             Resolve drift via atomic commits (Default)

Options (run):
  --dry-run       Show what commits would be made without executing them
  --task-id <id>  The current task ID to associate with commits
  --message <m>   Optional base message prefix
  -h, --help      Show this help message

Example:
  dev.kit sync prepare main
  dev.kit sync run --task-id "TASK-123"
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
      ;;
  esac
}
