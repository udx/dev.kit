---
name: dev-prompt
description: Generate an advanced dev.kit prompt artifact for AI integration using dev.kit prompt.
---

# dev-prompt

Purpose: Produce a high-quality, repo-scoped prompt artifact by invoking `dev.kit prompt`.

## Config

Inputs (use defaults when missing):
- `dev_prompt.request` (required)
- `dev_prompt.template` (default: `ai.codex`)
- `dev_prompt.out` (default: `{{DEV_KIT_STATE}}/codex/prompts/<repo-id>/<timestamp>.md`)
- `dev_prompt.repo_id` (default: derive from repo root name)

## Logic

1) Validate inputs
- Require a non-empty `dev_prompt.request`.
- If `dev_prompt.out` is not provided, generate a timestamped path under `{{DEV_KIT_STATE}}/codex/prompts/<repo-id>/`.

2) Generate prompt
- Run:
  `dev.kit prompt --request "<request>" --template <template> --out <out>`
- If `dev.kit prompt` fails, report the error and stop.

3) Report
- Return the output path and a one-line summary of what was generated.

## Schema

Inputs:
- `request` (string, required)
- `template` (string, optional)
- `out` (path, optional)
- `repo_id` (string, optional)

Outputs:
- `prompt_path` (path)
- `summary` (string)

Format:
- Markdown prompt file

## Docs

References:
- `docs/prompts.md`
- `docs/execution/iteration-loop.md`
