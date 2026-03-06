# Integration Configuration

Domain: AI Integration

## Purpose

Define how integrations are enabled through contract-driven wiring.

## Supported AI Providers

Different AI providers leverage unique mechanisms to enforce repository-bound grounding. Explore the provider-specific documentation for details:

- **[Gemini Integration](integrations/gemini.md)**: Native grounding via `GEMINI.md` hooks and `system.md` instructions.
- **[Codex Integration](integrations/codex.md)**: Config-driven orchestration using `config.toml` and the rules engine.

## Behavior

- Integrations are opt-in.
- Global config stays minimal by default.
- Local overrides are temporary and explicit.
- AI integrations require `ai.enabled = true` to allow `dev.kit skills run` to run external AI CLIs.
- When `ai.enabled = false`, `dev.kit skills run` prints the normalized prompt for manual use (Codex session, `codex exec`, or other AI/API/MCP tools).

## Constraints

- Avoid hidden side effects.
- Integrations must be reversible.
- Configuration must not bypass CDE contracts.
