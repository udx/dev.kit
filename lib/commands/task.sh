#!/bin/bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

print_task_usage() {
  cat <<'TASK_USAGE'
Usage: dev.kit task <command> [TASK_ID]

Commands:
  start "<req>" Initialize a new task with a generated ID and request
  log           Show session capture and interaction logs
  reset         Clear repository-scoped session context
  new <id>      Initialize a new task directory with prompt/feedback templates
  apply <id>    Apply task feedback to create/update a workflow
TASK_USAGE
}

dev_kit_cmd_task() {
  local sub="${1:-}"
  
  if [ -z "$sub" ] || [ "$sub" = "help" ] || [ "$sub" = "-h" ]; then
    print_task_usage
    exit 0
  fi

  local repo_root
  repo_root="$(get_repo_root || true)"
  if [ -z "$repo_root" ]; then
    repo_root="$PWD"
  fi

  case "$sub" in
    log)
      if command -v dev_kit_cmd_capture >/dev/null 2>&1; then
        dev_kit_cmd_capture show
      else
        echo "Error: Capture logic not loaded." >&2
        exit 1
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
      local task_dir="$repo_root/tasks/$task_id"
      
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
      echo "Location: tasks/$task_id/"
      ;;
    new)
      local task_id="${2:-}"
      if [ -z "$task_id" ]; then echo "Error: TASK_ID required"; exit 1; fi
      local task_dir="$repo_root/tasks/$task_id"
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
      local task_dir="$repo_root/tasks/$task_id"
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
