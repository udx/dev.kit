---
name: prompt-router
description: Route user prompts into iteration vs workflow generation. Use when the user requests iteration, or when a prompt likely exceeds bounded work and needs prompt-as-workflow conversion.
---

# Prompt Router

Purpose: Decide whether to run the iteration stages or generate a workflow.

## Config

Inputs are derived from the repo and environment when not provided explicitly.

- `router.repo_id` (default: basename of repo root)
- `router.workflow_dir` (default: `~/.udx/dev.kit/state/codex/workflows/<repo-id>`)
- `router.bounded_work` (default: values in Schema)

## Logic

Routing rules:
- If the prompt is exactly "iteration" or explicitly requests iteration: use iteration stages.
- If the prompt exceeds bounded-work limits or spans distinct deliverables: generate a workflow.
- If ambiguous: ask a clarifying question and propose the likely path.

## Schema

Bounded-work defaults:
- max_steps_per_iteration: 6
- max_files_per_step: 8
- max_new_files_per_iteration: 3
- max_move_operations_per_step: 0
- extract_child_workflow_if_any_exceeded: true

## Output Rules

- When routing to iteration: emit a short plan aligned to the iteration stages.
- When routing to workflow: emit a workflow artifact path under
  `~/.udx/dev.kit/state/codex/workflows/<repo-id>/<task-id>/workflow.md`, and pause
  for preview/approval after the root workflow is created.
