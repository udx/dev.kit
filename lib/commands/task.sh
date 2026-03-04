#!/bin/bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

print_task_usage() {
  cat <<'TASK_USAGE'
Usage: dev.kit task <command> [TASK_ID]

Commands:
  new <id>      Initialize a new task directory with prompt/feedback templates
  run <id>      Execute a task prompt and append output to feedback
  apply <id>    Apply task feedback to create/update a workflow
TASK_USAGE
}

dev_kit_cmd_task() {
  shift || true
  local sub="${1:-}"
  local task_id="${2:-}"

  if [ -z "$sub" ] || [ "$sub" = "help" ] || [ "$sub" = "-h" ]; then
    print_task_usage
    exit 0
  fi

  if [ -z "$task_id" ]; then
    echo "Error: TASK_ID is required for 'task $sub'" >&2
    exit 1
  fi

  local repo_root
  repo_root="$(get_repo_root || true)"
  if [ -z "$repo_root" ]; then
    repo_root="$PWD"
  fi

  local task_dir="$repo_root/tasks/$task_id"

  case "$sub" in
    new)
      if [ -e "$task_dir" ]; then
        echo "Error: Task already exists: $task_dir" >&2
        exit 1
      fi
      mkdir -p "$task_dir"
      cat > "$task_dir/prompt.md" <<EOF
# Task — $task_id
status: draft
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Scope
- <short scope statement>

## Inputs
- <paths or artifacts>

## Outputs
- <expected artifacts>

## Constraints
- deterministic
- tool-neutral
- no execution

## Request
<task instructions>
EOF
      cat > "$task_dir/feedback.md" <<EOF
# Feedback — $task_id
status: pending

## Output
- <request|command|artifact|workflow>

## Notes
EOF
      echo "Task initialized: $task_dir"
      ;;
    run)
      local prompt_file="$task_dir/prompt.md"
      local feedback_file="$task_dir/feedback.md"
      if [ ! -f "$prompt_file" ]; then
        echo "Error: Missing prompt: $prompt_file" >&2
        exit 1
      fi
      if [ ! -f "$feedback_file" ]; then
        echo "Error: Missing feedback: $feedback_file" >&2
        exit 1
      fi
      if ! command -v codex >/dev/null 2>&1; then
        echo "Error: codex not found. Cannot run task." >&2
        exit 1
      fi
      echo "Running task: $task_id ..."
      local report
      report="$(codex exec "$(cat "$prompt_file")")"
      {
        printf "\n\n---\n"
        printf "run: %s\n\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        printf "%s\n" "$report"
      } >> "$feedback_file"
      echo "Feedback written: $feedback_file"
      ;;
    apply)
      local feedback_file="$repo_root/docs/_feedback.md"
      local workflow_file="$task_dir/workflow.md"
      # Fallback to local feedback if docs/_feedback.md missing
      if [ ! -f "$feedback_file" ]; then
        feedback_file="$task_dir/feedback.md"
      fi
      if [ ! -f "$feedback_file" ]; then
        echo "Error: No feedback file found to apply." >&2
        exit 1
      fi
      mkdir -p "$task_dir"
      if [ ! -f "$workflow_file" ]; then
        cat > "$workflow_file" <<EOF
# Workflow — $task_id

status: draft
source: $(basename "$feedback_file")
scope: workspace

## Purpose
Define a bounded, deterministic workflow for $task_id.

## Steps
### Step 1 — Clarify scope
done: false
Task: Restate the task and identify inputs.

### Step 2 — Produce artifact plan
done: false
Task: Define minimal artifacts.

### Step 3 — Draft changes
done: false
Task: Draft proposed content changes.

### Step 4 — Validation
done: false
Task: Define verification steps.

## Intended File Edits (Proposed)
- <path>: <short intent>
EOF
      else
        {
          printf "\n\n## Update Log\n"
          printf "- %s: Workflow touched by 'task apply' for %s\n" \
            "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$task_id"
        } >> "$workflow_file"
      fi
      echo "Workflow ready: $workflow_file"
      ;;
    *)
      echo "Unknown task command: $sub" >&2
      exit 1
      ;;
  esac
}
