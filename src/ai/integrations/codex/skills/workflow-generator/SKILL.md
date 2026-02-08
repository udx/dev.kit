---
name: workflow-generator
description: Generate or refactor workflow documents with codex exec steps, including extraction gates and child workflows. Use when the user asks to create a workflow, update a workflow, or split steps into child workflows.
---

# Workflow Generator

Use this skill to convert ad-hoc requests into workflow documents that follow the codex exec format.

## Config

Inputs are derived from the repo and environment when not provided explicitly.

- `workflow.repo_id` (default: basename of repo root)
- `workflow.workflow_dir` (default: `~/.udx/dev.kit/state/codex/workflows/<repo-id>`)
- `workflow.template` (default: Schema below)

## Logic

Prompt-as-workflow approach:
- Derive the minimal number of steps required to complete the request.
- Each step must include: Task, Input, Logic/Tooling, Expected output/result.
- Use `codex exec` for each step.
- If a step has 2+ Extraction Gate "yes" answers, extract it as a child workflow.
- When extracting, defer child workflow creation until that parent step is iterated.
- Keep steps deterministic, plan-first, and repo-scoped.

Extraction Gate:
1) Any step exceeds bounded-work limits.
2) Task has distinct deliverables that can be independently reviewed.
3) Task spans multiple domains likely to exceed one-exec scope.
4) Task needs commands outside the allowed command surface or extra validation.

## Schema

Workflow template:

workflow:
  output_type: prompt
  bounded_work:
    max_steps_per_iteration: 6
    max_files_per_step: 8
    max_new_files_per_iteration: 3
    max_move_operations_per_step: 0
    extract_child_workflow_if_any_exceeded: true

steps:
  - task: <short description>
    input: <files or artifacts>
    logic_tooling: <commands or reasoning steps>
    expected_output: <result>
    done: false

## Placement Rules

- Use a stable `<repo-id>` (default: basename of repo root).
- Parent workflows live in `~/.udx/dev.kit/state/codex/workflows/<repo-id>/`.
- Child workflows live under `~/.udx/dev.kit/state/codex/workflows/<repo-id>/<parent>/<child>/index.md`.
- Keep filenames stable and human-readable.

## Execution Rule

- Child workflows are not generated during root workflow creation; they are created only when the parent step is iterated.
