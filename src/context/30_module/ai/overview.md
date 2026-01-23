# AI Integration Overview

Goal
- Provide a consistent AI integration layer across Codex, Claude, and Gemini.
- Keep docs as the source of truth and avoid AI->dev.kit->AI loops.

Core Behavior
- If dev.kit output is already provided, treat it as the source of truth.
- Require confirmation before running any pipeline step.
- Prefer dev.kit references and docs over generic advice.

AI Clients (dynamic)
$child

Non-executable example
```
$child
```

MCP Servers
- See `./mcp.md` for MCP configuration.
