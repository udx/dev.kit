---
name: iteration
description: Define and enforce the repo-native iteration contract for agents.
---

# Skill — Iteration Contract Builder

Purpose: Define and enforce the repo-native iteration contract for agents.

## See Also

- Spec kernel entrypoint: `docs/index.md`
- Iteration loop: `docs/execution/iteration-loop.md`
- Subtask loop: `docs/execution/subtask-loop.md`
- Repo overview: `README.md`
- Iteration stages: `references/iteration-stages.md`
- Iteration manifest: `manifests/iteration-manifest.md`

## Allowed Outputs
- request
- command
- artifact
- workflow

## Rules
- Execution is allowed when required by an iteration stage or explicitly requested.
- Ask for confirmation before destructive actions (delete, overwrite, reset, uninstall).
- Read `docs/_feedback.md` as the source of review tasks.
- Generate workflows under `.udx/dev.kit/workflows/<task-id>/workflow.md`.
- Steps MUST be bounded, deterministic, and have explicit inputs/outputs.
- Never mutate intent. Only propose changes via artifacts.
- Mark review items resolved by updating the resolution log in `docs/_feedback.md`.
- Mark subtask items resolved in `tasks/<task-id>/feedback.md`.
- When generating a root workflow, pause and present a preview for user approval before any child workflow work.

## Workflow Schema Requirements
- `workflow.output_type` must be `prompt` or `markdown`.
- `workflow.bounded_work` must include:
  - max_steps_per_iteration
  - max_files_per_step
  - max_new_files_per_iteration
  - max_move_operations_per_step
  - extract_child_workflow_if_any_exceeded
- Step `status` must be one of: planned, in_progress, done, blocked.
- Step `actions` must use CLI primitives: read, write, validate, report, execute, capture.

## Single-exec Bounds (defaults)
- max_steps_per_iteration: 6
- max_files_per_step: 8
- max_new_files_per_iteration: 3
- max_move_operations_per_step: 0
- extract_child_workflow_if_any_exceeded: true

## Extraction Gate (2+ YES => child workflow)
1) Any step exceeds bounded-work limits.
2) Task has distinct deliverables that can be independently reviewed.
3) Task spans multiple domains likely to exceed one-exec scope.
4) Task needs commands outside the allowed command surface or extra validation.

## Allowed Command Surface
- Discover available CLI commands at runtime (e.g., `dev.kit --list` or `--help`) before invoking them.
- Use only commands that are explicitly available in the current environment.
- Ask for confirmation before destructive commands (delete, overwrite, reset, uninstall).

## How to Consume `docs/_feedback.md`
- Identify unresolved items by task ID (e.g., DOC-002, MF-001).
- Preserve original task language; only add structured workflow steps.
- If the task is ambiguous, emit a `request` output.

## Iteration Routing
- If the prompt is "iteration" or explicitly requests iteration, run the iteration stages.
- If the prompt exceeds the bounded-work limits or spans distinct deliverables, generate a workflow using the prompt-as-workflow approach and return a workflow artifact.
- Use `.udx/dev.kit/workflows/<task-id>/workflow.md` for parent workflows and `.udx/dev.kit/workflows/<parent>/<child>/index.md` for children.
- Defer child workflow creation until the parent step is iterated.

## Iteration Stages (default)
1) Parse input/prompt
2) Validate intent and constraints
3) Execute bounded work (read/write/execute)
4) Process results
5) Run tests/validation (when applicable)
6) Prepare response (terse summary + next action)

## Workflow Generation
Each workflow file MUST include:
- Task ID and scope
- Inputs (files or artifacts)
- Step list with deterministic boundaries
- Intended file edits (proposed only)
- Validation or verification checks
 - Step metadata including `done: false|true`

## Resolution Log Update
- Append a resolution entry with task ID, file path(s), and summary.
- Do not remove prior entries.

## Done Criteria
- All workflow steps marked done.
- Resolution log updated.
- No outstanding questions for the task.
