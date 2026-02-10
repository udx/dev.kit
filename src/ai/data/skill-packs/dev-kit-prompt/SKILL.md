---
name: dev-kit-prompt
description: Generate an advanced dev.kit prompt artifact for AI integration using dev.kit prompt.
---

## Purpose
Produce a high-quality, repo-scoped prompt artifact by invoking `dev.kit prompt`.


## Required Inputs
- `dev_prompt.request` (non-empty).


## Config
- Inputs (use defaults when missing):
- `dev_prompt.request` (required)
- `dev_prompt.template` (default: `ai.codex`)
- `dev_prompt.out` (default: `/Users/jonyfq/.udx/dev.kit/state/codex/prompts/<repo-id>/<timestamp>.md`)
- `dev_prompt.repo_id` (default: derive from repo root name)


## Logic
- Validate inputs and require a non-empty `dev_prompt.request`.
- If `dev_prompt.out` is not provided, generate a timestamped path under `/Users/jonyfq/.udx/dev.kit/state/codex/prompts/<repo-id>/`.
- Run: `dev.kit prompt --request "<request>" --template <template> --out <out>`.
- If `dev.kit prompt` fails, report the error and stop.
- Return the output path and a one-line summary.


## Schema
- Inputs: request (string, required), template (string, optional), out (path, optional), repo_id (string, optional)
- Outputs: prompt_path (path), summary (string)
- Format: Markdown prompt file


## Output Rules
- Return the output path and a one-line summary.


## Docs
- `docs/prompts.md`
- `docs/execution/iteration-loop.md`
