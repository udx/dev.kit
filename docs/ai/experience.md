# AI Integration Experience

Domain: AI Integration

## Purpose

Define the user experience for dev.kit with and without AI integrations.

## Common Flow (Prompt First)

- `dev.kit prompt` generates the normalized prompt artifact.
- `dev.kit exec` wraps prompt generation and runs Codex when enabled.
- Prompts always include `$dev-kit-prompt-router` and workflow/continuity rules.

Flow diagram:

```
User input
  -> dev.kit exec "..."
     -> dev.kit prompt (ai / ai.codex)
     -> codex exec "<normalized prompt>"

Manual path
  -> dev.kit prompt --request "..." --template ai.codex
     -> codex exec "<normalized prompt>"
```

## Mode A — AI Disabled (default)

Config:
- `ai.enabled = false`
- `exec.prompt = ai` (default)

Behavior:
- `dev.kit exec` prints the normalized prompt and exits.
- Use the output with Codex sessions, `codex exec`, Context7 MCP, or a REST client.

## Mode B — AI Enabled + Codex CLI

Config:
- `ai.enabled = true`
- `exec.prompt = ai.codex.min` (default)
- `exec.stream = false` (default)

Behavior:
- `dev.kit exec` runs `codex exec` using the normalized prompt.
- dev.kit stores prompt/request/result logs under `{{DEV_KIT_STATE}}/codex/logs/<repo-id>/`.
- Codex stores its own sessions under `~/.codex/sessions`.

## Context Persistence

When enabled, dev.kit appends the latest request/response to a repo-scoped
context file and includes it in subsequent prompts.

Config:
- `context.enabled = true` (default)
- `context.dir = <path>` (optional override)
- `context.max_bytes = 4000` (default)

Behavior:
- When a `## Context` section is present, treat it as repo-scoped persistent memory.

Commands:
- `dev.kit context show`
- `dev.kit context reset`
- `dev.kit context compact`
- `dev.kit exec --no-context`

## Mode C — AI Enabled but Codex Missing

Config:
- `ai.enabled = true`

Behavior:
- `dev.kit exec` reports that `codex` is missing.
- Use `dev.kit exec --print` or `dev.kit prompt` to obtain the prompt manually.

## Codex Config Apply

- `dev.kit codex config all --apply` renders `src/ai/data` using Codex schemas/templates into `~/.codex/`.
- `dev.kit codex apply` remains as a legacy alias for full apply.
- This installs `AGENTS.md`, `config.toml`, `rules/default.rules`, and managed `dev-kit-*` skills.
- Non-`dev-kit-*` skills already present in `~/.codex/skills` are preserved.
- Skills may be rendered from JSON sections or copied from `src/ai/data/skill-packs/<skill-name>/` when present.
- The prompt + skills remain the primary integration point; Codex config provides baseline behavior.

## Continuity Across Turns

- Use the workflow file path and current step ID from the last response when continuing.
- For non-interactive runs, use `codex exec --resume` to continue the most recent session.
- For interactive sessions, use `codex resume` to reopen a prior thread.
