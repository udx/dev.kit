# Prompts

Structure (under `templates/prompts/`):
- `index.md`: base prompt (default context rules)
- `ai/index.md`: AI middleware overrides (applied with base)
- `ai/codex/index.md`: Codex overrides (applied with base + AI)
- `ai/claude/index.md`: Claude overrides (applied with base + AI)
- `developer/index.md`: developer overrides (applied with base)

Template:
- Prompts are intentionally minimal; the base prompt is inherited by default and overrides add role-specific rules.

Prompt selection:
- Local config: `./.udx/dev.kit/config.env` (if present)
- Global config: `~/.udx/dev.kit/config.env`
- Precedence: local overrides global.

Keys:
- `exec.prompt`: `base|ai|ai.codex|ai.claude|developer|<path>`

CLI:
- `dev.kit prompt` generates the normalized prompt artifact (stdout or `--out`).
- `dev.kit exec` reuses the same prompt generator before running `codex exec`.
