# Prompts

Structure (under `src/prompts/`):
- `index.md`: base prompt (default context rules)
- `src/prompts/ai/index.md`: AI middleware overrides (applied with base)
- `src/prompts/ai/codex/index.md`: Codex overrides (applied with base + AI)
- `src/prompts/ai/claude/index.md`: Claude overrides (applied with base + AI)
- `src/prompts/developer/index.md`: developer overrides (applied with base)

Template:
- Prompts are intentionally minimal; the base prompt is inherited by default and overrides add role-specific rules.

Prompt selection:
- Local config: `.udx/dev.kit/config.env` (created on demand)
- Global config: `~/.udx/dev.kit/config.env` (created by installer)
- Precedence: local overrides global.

Keys:
- `exec.prompt`: `base|ai|ai.codex|ai.claude|developer|<path>`

CLI:
- `dev.kit prompt` generates the normalized prompt artifact (stdout or `--out`).
- `dev.kit exec` reuses the same prompt generator before running `codex exec`.
