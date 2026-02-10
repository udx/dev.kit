---
name: dev-kit-workflow-generator
description: Generate or refactor workflow documents with codex exec steps, including extraction gates and child workflows. Use when the user asks to create a workflow, update a workflow, or split steps into child workflows.
---

## Purpose
Create or refactor workflow documents based on a prompt-as-workflow spec.


## Required Inputs
- User request (verbatim from `## User Request`).


## Config
- Inputs come from the user request and repo context.
- `workflow.workflow_dir` (default: `~/.udx/dev.kit/state/codex/workflows/<repo-id>`)
- `workflow.output_type` (required: `prompt` or `markdown`)


## Logic
- Parse the user intent and scope.
- Apply the extraction gate to decide if child workflows are required.
- Create a workflow file with bounded steps and explicit inputs/outputs.
- If required, propose child workflows but do not generate them until parent iteration.


## Schema
- Inputs: prompt, repo context, constraints
- Outputs: workflow markdown
- Format: markdown file with step metadata


## Output Rules
- Return the workflow path and a brief summary.


## Docs
- `docs/execution/prompt-as-workflow.md`
- `docs/execution/extraction-gate.md`
