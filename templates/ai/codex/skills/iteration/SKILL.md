---
name: iteration
description: Define and enforce the repo-native iteration contract for agents.
---

# Iteration

Purpose: Define and enforce the repo-native iteration contract for agents.

## Config

Inputs are derived from the repo and environment when not provided explicitly.

- `iteration.repo_id` (default: basename of repo root)
- `iteration.workflow_dir` (default: `~/.udx/dev.kit/state/codex/workflows/<repo-id>`)
- `iteration.task_id` (required for workflow creation)
- `iteration.review_log` (default: `docs/_feedback.md`)
- `iteration.subtask_log` (default: `tasks/<task-id>/feedback.md`)

## Logic

Default iteration stages:
1) Parse input/prompt
2) Validate intent and constraints
3) Execute bounded work (read/write/execute)
4) Process results
5) Run tests/validation (when applicable)
6) Prepare response (terse summary + next action)

## Schema

Bounded-work manifest:
- max_steps_per_iteration: 6
- max_files_per_step: 8
- max_new_files_per_iteration: 3
- max_move_operations_per_step: 0
- extract_child_workflow_if_any_exceeded: true

## Rules

- Execution is allowed when required by an iteration stage or explicitly requested.
- Ask for confirmation before destructive actions (delete, overwrite, reset, uninstall).
- Read `docs/_feedback.md` as the source of review tasks.
- Use a stable `<repo-id>` (default: basename of repo root) for all workflow paths.
- Generate workflows under `~/.udx/dev.kit/state/codex/workflows/<repo-id>/<task-id>/workflow.md`.
- Steps MUST be bounded, deterministic, and have explicit inputs/outputs.
- Never mutate intent. Only propose changes via artifacts.
- Mark review items resolved by updating the resolution log in `docs/_feedback.md`.
- Mark subtask items resolved in `tasks/<task-id>/feedback.md`.
- When generating a root workflow, pause and present a preview for user approval before any child workflow work.

## Routing

- If the prompt is "iteration" or explicitly requests iteration, run the default stages.
- If the prompt exceeds the bounded-work limits or spans distinct deliverables, generate a workflow.
- Use parent path `~/.udx/dev.kit/state/codex/workflows/<repo-id>/<task-id>/workflow.md`.
- Use child path `~/.udx/dev.kit/state/codex/workflows/<repo-id>/<parent>/<child>/index.md`.

## Done Criteria

- All workflow steps marked done.
- Resolution log updated.
- No outstanding questions for the task.
