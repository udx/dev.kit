# Codex Rules (Derived)

Core behavior
- Do not call `dev.kit -p` from Codex CLI to avoid loops.
- If dev.kit output is already provided, treat it as the source of truth.
- If dev.kit returns a pipeline, require user confirmation before running any step.
- Prefer dev.kit references and docs over generic advice.

Safety
- Require previews for apply/push/destructive steps.
- Keep changes small and reversible.
- Never auto-move secrets; only suggest secure storage options.

Prompting
- Follow Codex prompting guidance for tool use and concise responses.
- Use capture logs for iteration: ask the user to run `dev.kit capture show` and review before cleaning.
