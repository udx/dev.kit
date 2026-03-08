#!/bin/bash

# @description: Manage the lifecycle of active workflows and sessions.
# @intent: task, session, workflow, start, reset
# @objective: Orchestrate the engineering lifecycle by initializing tasks, tracking context, and managing the 'tasks/' directory through discovery and cleanup.
# @usage: dev.kit task start "Implement new feature"
# @usage: dev.kit task list
# @usage: dev.kit task cleanup
# @workflow: 1. Start Task -> 2. Normalize Intent -> 3. Iterate (Implementation/Verification) -> 4. Finalize Sync -> 5. Cleanup Completed Tasks

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

print_task_usage() {
  cat <<'TASK_USAGE'
Usage: dev.kit task <command> [TASK_ID]

Commands:
  start "<req>" Initialize a new task with a generated ID and request
  list          Briefly list all tasks and their status
  cleanup       Remove completed or stale tasks from the workspace
  reset         Clear repository-scoped session context
  new <id>      Initialize a new task directory with templates
  apply <id>    Apply task feedback to create/update a workflow
TASK_USAGE
}

# Helper to check if a task is stale (not modified in 2 days)
_is_task_stale() {
  local task_dir="$1"
  # -mtime +1 matches anything not modified in >48 hours
  [ -n "$(find "$task_dir" -mtime +1 -print -quit 2>/dev/null)" ]
}

dev_kit_cmd_task() {
  local sub="${1:-}"
  
  if [ -z "$sub" ] || [ "$sub" = "help" ] || [ "$sub" = "-h" ]; then
    print_task_usage
    exit 0
  fi

  local tasks_dir
  tasks_dir="$(get_tasks_dir)"

  case "$sub" in
    list)
      [ ! -d "$tasks_dir" ] && { echo "No tasks found."; return 0; }
      printf "\n%sActive & Recent Tasks:%s\n" "$(ui_cyan)" "$(ui_reset)"
      find "$tasks_dir" -mindepth 1 -maxdepth 1 -type d | sort -r | while read -r task_dir; do
        local task_id; task_id="$(basename "$task_dir")"
        local status="initialized"
        if [ -f "$task_dir/workflow.md" ]; then
          status="$(grep "^status:" "$task_dir/workflow.md" | head -n 1 | awk '{print $2}')"
        elif [ -f "$task_dir/plan.md" ]; then
          status="$(grep "^status:" "$task_dir/plan.md" | head -n 1 | awk '{print $2}')"
        fi

        local stale_marker=""
        if _is_task_stale "$task_dir" && [[ "$status" != "done" && "$status" != "completed" ]]; then
          stale_marker=" $(ui_orange)⚠️ stale$(ui_reset)"
        fi

        printf "  %-20s %s%s\n" "$task_id" "$status" "$stale_marker"
      done
      echo ""
      ;;
    active)
      [ ! -d "$tasks_dir" ] && { echo "No active tasks."; return 0; }
      local count=0
      while read -r task_dir; do
        local task_id; task_id="$(basename "$task_dir")"
        local status="initialized"
        if [ -f "$task_dir/workflow.md" ]; then
          status="$(grep "^status:" "$task_dir/workflow.md" | head -n 1 | awk '{print $2}')"
        elif [ -f "$task_dir/plan.md" ]; then
          status="$(grep "^status:" "$task_dir/plan.md" | head -n 1 | awk '{print $2}')"
        fi
        
        if [[ "$status" != "done" && "$status" != "completed" ]]; then
          ((count++))
          local objective; objective="$(grep -A 2 "## Objective" "$task_dir/plan.md" 2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*//' || echo "No objective defined.")"
          local stale_marker=""
          if _is_task_stale "$task_dir"; then stale_marker=" [STALE]"; fi
          echo "- [$task_id] status: $status$stale_marker"
          echo "  objective: $objective"
        fi
      done < <(find "$tasks_dir" -mindepth 1 -maxdepth 1 -type d | sort -r)
      
      if [ "$count" -eq 0 ]; then
        echo "No active tasks."
      fi
      ;;
    reminder)
      [ ! -d "$tasks_dir" ] && return 0
      local stale_count=0
      while read -r task_dir; do
        local status=""
        if [ -f "$task_dir/workflow.md" ]; then
          status="$(grep "^status:" "$task_dir/workflow.md" | head -n 1 | awk '{print $2}')"
        elif [ -f "$task_dir/plan.md" ]; then
          status="$(grep "^status:" "$task_dir/plan.md" | head -n 1 | awk '{print $2}')"
        fi
        
        if [[ "$status" != "done" && "$status" != "completed" ]] && _is_task_stale "$task_dir"; then
          ((stale_count++))
        fi
      done < <(find "$tasks_dir" -mindepth 1 -maxdepth 1 -type d)
      
      if [ "$stale_count" -gt 0 ]; then
        ui_tip "You have $stale_count stale tasks (older than 2 days). Run 'dev.kit task cleanup' to clear them."
      fi
      ;;
    cleanup)
      [ ! -d "$tasks_dir" ] && return 0
      echo "Scanning for tasks to cleanup..."
      local to_remove=()
      while read -r task_dir; do
        local task_id; task_id="$(basename "$task_dir")"
        local status=""
        if [ -f "$task_dir/workflow.md" ]; then
          status="$(grep "^status:" "$task_dir/workflow.md" | head -n 1 | awk '{print $2}')"
        elif [ -f "$task_dir/plan.md" ]; then
          status="$(grep "^status:" "$task_dir/plan.md" | head -n 1 | awk '{print $2}')"
        fi
        
        if [[ "$status" == "done" || "$status" == "completed" ]] || _is_task_stale "$task_dir"; then
          to_remove+=("$task_dir")
        fi
      done < <(find "$tasks_dir" -mindepth 1 -maxdepth 1 -type d)
      
      if [ ${#to_remove[@]} -eq 0 ]; then
        echo "Nothing to cleanup."
        return 0
      fi
      
      echo "Tasks identified for removal (completed or stale):"
      for tr in "${to_remove[@]}"; do
        echo "  - $(basename "$tr")"
      done
      
      printf "Remove these %d tasks? (y/N): " "${#to_remove[@]}"
      read -r response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        for tr in "${to_remove[@]}"; do
          rm -rf "$tr"
        done
        echo "Cleanup complete."
      else
        echo "Cleanup aborted."
      fi
      ;;
    reset)
      if context_enabled; then
        local ctx
        ctx="$(context_file || true)"
        if [ -f "$ctx" ]; then
          : > "$ctx"
          echo "Session context cleared."
        fi
      fi
      ;;
    start)
      local request="${2:-}"
      if [ -z "$request" ] && [ ! -t 0 ]; then
        request="$(cat)"
      fi
      if [ -z "$request" ]; then
        echo "Error: Request is required for 'task start'" >&2
        exit 1
      fi
      
      local task_id
      task_id="TASK-$(date +%Y%m%d-%H%M)"
      local task_dir="$tasks_dir/$task_id"
      
      mkdir -p "$task_dir"
      cat > "$task_dir/plan.md" <<EOF
# Task Plan — $task_id
status: draft
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Objective
$request

## Steps
- [ ] Normalize intent
- [ ] Resolve dependencies
- [ ] Implementation
- [ ] Verification
EOF
      cat > "$task_dir/feedback.md" <<EOF
# Feedback — $task_id
status: pending
EOF
      echo "Task initialized: $task_id"
      echo "Location: .udx/dev.kit/tasks/$task_id/"
      ;;
    new)
      local task_id="${2:-}"
      if [ -z "$task_id" ]; then echo "Error: TASK_ID required"; exit 1; fi
      local task_dir="$tasks_dir/$task_id"
      if [ -e "$task_dir" ]; then echo "Error: Task exists"; exit 1; fi
      mkdir -p "$task_dir"
      cat > "$task_dir/prompt.md" <<EOF
# Task — $task_id
status: draft
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Scope
- <short scope statement>

## Request
<task instructions>
EOF
      cat > "$task_dir/feedback.md" <<EOF
# Feedback — $task_id
status: pending
EOF
      echo "Task initialized: $task_dir"
      ;;
    apply)
      local task_id="${2:-}"
      if [ -z "$task_id" ]; then echo "Error: TASK_ID required"; exit 1; fi
      local task_dir="$tasks_dir/$task_id"
      local feedback_file="$repo_root/docs/_feedback.md"
      local workflow_file="$task_dir/workflow.md"
      [ ! -f "$feedback_file" ] && feedback_file="$task_dir/feedback.md"
      if [ ! -f "$feedback_file" ]; then echo "Error: No feedback"; exit 1; fi
      
      mkdir -p "$task_dir"
      if [ ! -f "$workflow_file" ]; then
        cat > "$workflow_file" <<EOF
# Workflow — $task_id
status: planned
source: $(basename "$feedback_file")

## Steps
### Step 1 — Normalize Inputs
status: planned
EOF
      else
        printf "\n- %s: Workflow updated\n" "$(date -u)" >> "$workflow_file"
      fi
      echo "Workflow ready: $workflow_file"
      ;;
    *)
      echo "Unknown task command: $sub" >&2
      exit 1
      ;;
  esac
}
