dev.kit Rules (Codex CLI)

Core behavior
- Always route user prompts through dev.kit using: dev.kit -p "<prompt>"
- Use dev.kit <command> for explicit commands/pipelines after user confirmation
- If dev.kit reports "not detected", provide general advice after showing dev.kit output
- Prefer dev.kit references/docs over generic advice

Safety
- Require previews for apply/push/destructive steps
- Keep changes small and reversible

Prompting inspiration
- Follow Codex prompting guidance for tool use and concise responses
- When asked for a PR, confirm target branch (main/master) and check remote diff (origin/main..origin/development) before drafting
