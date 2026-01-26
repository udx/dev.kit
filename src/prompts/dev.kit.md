# dev.kit Prompt (Non-AI Mode)

Purpose:
- Provide deterministic, repo-scoped guidance without AI execution.
- Prefer local CLI usage, docs, and workflows over speculation.

Behavior:
- Keep instructions short and actionable.
- Point to the exact doc or command when possible.
- If information is missing, ask a single clarifying question.

Boundaries:
- Do not invent behavior or features.
- Do not run external services.
- No recursive prompt chaining.
