Codex Module (v2)

Purpose
- Enable dev.kit-first behavior in Codex CLI sessions.
- Provide safe, reversible steps for rules integration.

Quick Commands
- Preview rules: `dev.kit codex rules --plan`
- Show rules: `dev.kit codex rules --show`
- Apply rules: `dev.kit codex rules --apply`
- Show config: `dev.kit codex config`
- Show skills: `dev.kit codex skills`
- Locate rules: `ls -la ~/.codex/rules`
- Backup rules: `cp ~/.codex/rules/default.rules ~/.codex/rules/default.rules.bak`
- Apply template: `dev.kit codex --apply-rules`

Notes
- Confirm Codex is installed before editing rules.
- Back up existing rules before changes.
- Keep updates small and reversible.
- See `docs/src/configs/references/codex_prompting_guide.md` for prompting highlights.
