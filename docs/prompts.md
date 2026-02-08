# Prompts

Structure (under `src/ai/`):
- `src/ai/data/prompts.json`: common prompt definitions (base + AI middleware)
- `src/ai/integrations/codex/prompts.json`: Codex-specific prompt overlay
- `src/ai/integrations/codex/schemas/prompts.schema.json`: JSON schema shared by prompt data files

Template:
- Prompts are intentionally minimal; overlays inherit base prompts using `inherits`.

Codex tips:
- The Codex overlay includes interactive tips and shortcuts such as `!` for running local shell commands, `@` for fuzzy file search, and `/review` or `/fork` slash commands for specialized workflows.

Prompt selection:
- Local config: `.udx/dev.kit/config.env` (created on demand)
- Global config: `~/.udx/dev.kit/config.env` (created by installer)
- Precedence: local overrides global.

Keys:
- `exec.prompt`: `base|ai|ai.codex`

CLI:
- `dev.kit prompt` generates the normalized prompt artifact (stdout or `--out`).
- `dev.kit exec` reuses the same prompt generator before running `codex exec`.
