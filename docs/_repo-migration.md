# Repo Migration Report — Canonical Roots and Subtask Loop

Date: 2026-01-26
Scope: promote `_research` content to canonical roots, remove legacy tree, add subtask loop.

## What Moved Where

| From | To |
| --- | --- |
| `_research/docs/**` | `docs/**` |
| `_research/docs/schemas/**` | `schemas/**` |
| `_research/workflows/**` | `workflows/**` |
| `_research/prompts/**` | `prompts/**` |
| `_research/scripts/**` | `scripts/**` |
| `_research/templates/**` | `templates/**` |
| `_research/assets/**` | `assets/**` |
| `_research/fixtures/**` | `assets/fixtures/**` |
| `_research/prompt.md` | `prompts/prompt.md` |
| `_research/skills/README.md` | `skills/README.md` |
| legacy-salvage-plan report (renamed) | `docs/legacy-salvage-plan.md` |
| legacy-retirement report (renamed) | `docs/legacy-retirement.md` |

## What Was Removed

- Legacy tree (entire directory removed after reference scan).

## Entrypoints Updated

- Root README entrypoints now point to `docs/` and `scripts/`.
- Doc index entrypoints now point to `docs/execution/iteration-loop.md` and `docs/execution/subtask-loop.md`.
- Iteration skill contract now points to `docs/`, `workflows/`, and `tasks/` paths.

## Subtask Loop (Prompt → Feedback)

Create a task:

- `scripts/new-task.sh <task-id>`

Run a task (write feedback only):

- `scripts/run-task.sh <task-id>`

Contract details live at:

- `docs/execution/subtask-loop.md`

## Legacy Removal Proof

Search patterns used (all returned 0 matches before removal):

- `rg "_legac""y" -n`
- `rg "_legac""y/" -n`

## Follow-Ups (Max 5)

1) Decide whether `assets/fixtures/` should remain tracked or be treated as generated output.
2) Add a brief policy line in `docs/README.md` clarifying doc ownership boundaries.
3) Consider a minimal `tasks/README.md` for onboarding the subtask loop.
4) Add a short validation checklist for subtask feedback outputs.
5) Confirm whether `docs/_feedback.md` should be trimmed or archived.
