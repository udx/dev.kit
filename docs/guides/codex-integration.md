Codex CLI Integration (v2)

Goal
- Route prompts through dev.kit before general LLM advice.
- Keep changes reversible and explicit.

Default Locations
- Rules: `~/.codex/rules/default.rules`
- Config: `~/.codex/config.env`

Safe Integration Steps
1) Confirm Codex is installed:
   - `command -v codex`
2) Back up rules:
   - `cp ~/.codex/rules/default.rules ~/.codex/rules/default.rules.bak`
3) Preview rules changes:
   - `dev.kit codex --plan-rules`
4) Apply dev.kit-first rules:
   - `dev.kit codex --apply-rules`

Inspect current rules:
- `dev.kit codex --get-rules`

Notes
- If rules file does not exist, run Codex once to create defaults.
- Use small, reversible edits to avoid breaking existing setups.
