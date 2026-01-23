# MCP Servers

Goal
- Use MCP servers as optional documentation sources when AI integration is enabled.
- Keep the mechanism consistent across Codex, Claude, and Gemini.

Standard Mechanism
- Each AI integration can declare MCP servers by name.
- When an AI client is enabled, dev.kit should ensure the configured MCP servers are available.
- MCP usage is read-only for docs; execution stays with dev.kit tooling.

Default MCP Servers
- Codex: openaiDeveloperDocs
- Claude: claudeDeveloperDocs (placeholder)
- Gemini: geminiDeveloperDocs (placeholder)

Notes
- MCP servers should be defined in the AI client config (e.g., Codex config).
- If an MCP server is unavailable, continue without blocking and note the fallback.
