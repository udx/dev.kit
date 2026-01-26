# Subtask Loop

Domain: Execution

## Purpose

Define a minimal, repo-native loop for task-specific prompt → feedback artifacts.
This loop is tool-neutral and produces no runtime side effects.

## Task Directory Layout

Each task lives under `tasks/<task-id>/` with the following files:

- `tasks/<task-id>/prompt.md`
- `tasks/<task-id>/feedback.md`
- `tasks/<task-id>/workflow.md` (optional)
- `tasks/<task-id>/artifacts/` (optional)

## Allowed Feedback Outputs

Feedback files must use one of these output types:

- request
- command
- artifact
- workflow

## Completion Rules

A task is complete when:

- `tasks/<task-id>/feedback.md` includes a clear completion marker.
- The final section lists affected paths and a concise outcome summary.

Recommended completion marker:

- `status: complete`

## Relationship to `docs/_feedback.md`

- `docs/_feedback.md` remains the review-log artifact for the doc review loop.
- Subtask outputs belong in `tasks/<task-id>/feedback.md` and should not be appended to `docs/_feedback.md`.
- If a subtask resolves an item from `docs/_feedback.md`, add a short resolution entry there that points to the task directory.

## Minimal Command Loop

Create a task:

- `scripts/new-task.sh <task-id>`

Run a task (write feedback only):

- `scripts/run-task.sh <task-id>`
