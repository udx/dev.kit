# Prompts

Structure (under `src/prompts/`):
- `index.md`: base prompt (non-AI)
- `ai/index.md`: AI base prompt
- `ai/codex/index.md`: Codex overrides
- `ai/claude/index.md`: Claude overrides
- `developer/index.md`: developer mode prompt

Template:
- These prompts follow the same 6-section structure used across the repo.

Prompt selection:
- Local config: `./.udx/dev.kit/config.env` (if present)
- Global config: `~/.udx/dev.kit/config.env`
- Precedence: local overrides global.

Keys:
- `exec.prompt`: `base|ai|ai.codex|ai.claude|developer|<path>`
