---
name: workflow-generator
description: Generate or refactor workflow documents with codex exec steps, including extraction gates and child workflows. Use when the user asks to create a workflow, update a workflow, or split steps into child workflows.
---

# Workflow Generator

Use this skill to convert ad-hoc requests into workflow documents that follow the codex exec format.

## Required references

Read this before generating or restructuring workflows:

- `references/prompt-as-workflow-approach.md`

## Workflow output rules

- Each step must include: Task, Input, Logic/Tooling, Expected output/result.
- Use `codex exec` for each step.
- Add `done: false` per step.
- If the Extraction Gate triggers (2+ yes), create a child workflow and reference it from the parent.
- Keep steps deterministic, plan-first, and repo-scoped.

## Placement rules

- Parent workflows live in `src/workflows/`.
- Child workflows live under `src/workflows/<parent>/<child>/index.md`.
- Keep filenames stable and human-readable.
