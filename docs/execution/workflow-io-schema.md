# Workflow IO Schema (DOC-003)

Domain: Execution

## Purpose

Define the minimal schema for prompt-as-workflow artifacts.

## Required Fields

```
workflow:
  id: string
  title: string
  output_type: prompt|markdown
  bounded_work:
    max_steps_per_iteration: number
    max_files_per_step: number
    max_new_files_per_iteration: number
    max_move_operations_per_step: number
    extract_child_workflow_if_any_exceeded: true|false
  steps:
    - id: string
      title: string
      inputs: [string]
      actions: [string]
      outputs: [string]
      status: planned|in_progress|done|blocked
```

## Rules

- `output_type` must align with DOC-002.
- Each step must be independently bounded.
- Workflow steps must be executable without optional extensions.
- If bounds are exceeded, extract a child workflow before continuing.
- Step `status` is required and must be one of: planned, in_progress, done, blocked.

## Continuation Guidance (Recommended)

For multi-turn work (interactive sessions or repeated `codex exec`):
- Persist step `status` changes in the workflow file.
- On every response, reference the active workflow path and current step ID.
- If blocked, record the missing inputs and keep the step status as `blocked`.
- For large tasks, use child workflows and reference them from the parent step.
