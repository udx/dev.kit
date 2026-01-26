# Skill — Iteration Contract Builder

Purpose: Define and enforce the repo-native iteration contract for agents.

## See Also

- Spec kernel entrypoint: `docs/index.md`
- Iteration loop: `docs/execution/iteration-loop.md`
- Subtask loop: `docs/execution/subtask-loop.md`
- Repo overview: `README.md`

## Allowed Outputs
- request
- command
- artifact
- workflow

## Rules
- No execution authority. Agents only produce artifacts and workflows.
- Read `docs/_feedback.md` as the source of review tasks.
- Generate workflows under `src/workflows/<task-id>/workflow.md`.
- Steps MUST be bounded, deterministic, and have explicit inputs/outputs.
- Never mutate intent. Only propose changes via artifacts.
- Mark review items resolved by updating the resolution log in `docs/_feedback.md`.
- Mark subtask items resolved in `tasks/<task-id>/feedback.md`.

## How to Consume `docs/_feedback.md`
- Identify unresolved items by task ID (e.g., DOC-002, MF-001).
- Preserve original task language; only add structured workflow steps.
- If the task is ambiguous, emit a `request` output.

## Workflow Generation
Each workflow file MUST include:
- Task ID and scope
- Inputs (files or artifacts)
- Step list with deterministic boundaries
- Intended file edits (proposed only)
- Validation or verification checks

## Resolution Log Update
- Append a resolution entry with task ID, file path(s), and summary.
- Do not remove prior entries.

## Done Criteria
- All workflow steps marked done.
- Resolution log updated.
- No outstanding questions for the task.
