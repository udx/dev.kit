---
name: workflow-generator
description: Generate or refactor workflow documents with codex exec steps, including extraction gates and child workflows. Use when the user asks to create a workflow, update a workflow, or split steps into child workflows.
---

# Workflow Generator

Use this skill to convert ad-hoc requests into workflow documents that follow the codex exec format.

## Required references

Read these before generating or restructuring workflows:

- `references/prompt-as-workflow-approach.md`
- `references/workflow_step_gates.md`
- `manifests/workflow-template.md`

## Workflow output rules

- Each step must include: Task, Input, Logic/Tooling, Expected output/result.
- Use `codex exec` for each step.
- Add `done: false` per step.
- After creating the root workflow, pause and present a preview so the user can approve or adjust scope/steps.
- If the Extraction Gate triggers (2+ yes), create a child workflow and reference it from the parent.
- Keep steps deterministic, plan-first, and repo-scoped.

## Placement rules

- Parent workflows live in `.udx/dev.kit/workflows/`.
- Child workflows live under `.udx/dev.kit/workflows/<parent>/<child>/index.md`.
- Keep filenames stable and human-readable.

## Execution rule

- Child workflows are not generated during root workflow creation; they are created only when the parent step is iterated.
