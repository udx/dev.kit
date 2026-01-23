# AI Integration Overview

Behavior
- Do not call `dev.kit -p` from Codex CLI to avoid loops.
- If dev.kit output is already provided, treat it as the source of truth.
- If `match=detected` and pipeline exists, require confirmation.

Data Sources (Fallback Order)
- Local docs and module metadata.
- UDX tooling repos via git/gh or cached clones.
- Web retrieval (e.g., `@udx/mcurl`) when needed.

Rules vs Config
- Rules define development standards and orchestration behavior.
- Config defines permissions and enabled features for each environment.
- Rules are versioned and templated; config is local and user-owned.

Codex Integration Inputs
- Prompt runner: https://developers.openai.com/codex/noninteractive
- Custom prompts: https://developers.openai.com/codex/custom-prompts
- Skills: https://developers.openai.com/codex/skills

Related Docs
- Rules: `public/ai/codex.rules.md`
- Module metadata: `public/modules/codex.json`
- Skills: `src/context/30_module/ai/codex/skills.md`
- MCP servers: `src/context/30_module/ai/codex/mcp.md`
- AI config: `src/context/20_config/ai/overview.md`
