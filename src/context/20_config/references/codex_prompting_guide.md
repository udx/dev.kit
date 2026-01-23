Codex Prompting Guide (Extracted Notes)

Source
- https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/
- Captured via `mcurl` for offline reference.

Purpose
- Summarize prompt guidance relevant to dev.kit integration.
- Keep rules short, actionable, and safe-by-default.

Key Highlights
- Prefer a strong base prompt (Codex-Max style) and add tactical rules.
- Avoid upfront plans/preambles that can interrupt long rollouts.
- Emphasize tool usage and exploration over freeform text.
- Encourage parallel tool calls when possible.
- Optimize for correctness and safe behavior, not shortcuts.

Integration Notes for dev.kit
- Always route user prompts through `dev.kit -p "<prompt>"`.
- Use `dev.kit <command_id>` for explicit workflows after confirmation.
- Require previews for apply/push/destructive actions.
- Keep edits small and reversible; avoid silent failures.
