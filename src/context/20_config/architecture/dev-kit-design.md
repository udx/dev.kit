Context from Dmytro (do not remove and stick it here until asked to remove)

Development Standards
- Modularization of logic: reusability, isolation of concerns, and graceful fallback when dependencies are missing.
- TDD: define expectations first and use tests to guide iteration.
- Configs are separated from the codebase.
- Use `src/context/20_config/development/v3-refs/` for additional context.

Design
- User experience is priority.
- Development experience is secondary but uses UX insights dynamically; consider `dev.kit mode --boss` for protected dev flows and iterative findings with captured context.
- User notices are friendly and not bothering, but present and useful.
- Concept definition follows development best practices and adapts Codex prompts to maximize implementation quality.

Modes
- Boss: protected development mode; requires auth (mocked for now). Full command set.
- Contribute: reduced command set for working on forks and sending PRs to UDX repos.
- User: default mode for end users; full feature set but no source modifications. User config is separate from source.

# dev.kit Design v3

Goal
- Ship a working dev.kit with a small, complete feature set fast.
- Keep a clean contract for install, configuration, and AI integration.
- Make behavior predictable, reversible, and safe by default.

Non-Goals (v3)
- Full IDE integrations.
- Multi-agent orchestration beyond simple pipelines.
- Deep secret manager integrations beyond detection and guided setup.

Principles
- Config driven: no baked-in values inside scripts.
- Bash-first: keep dependencies minimal, add tools only when needed.
- Optional engines: detect and adapt, never hard-fail on missing tools.
- Explicit safety: confirmation for destructive or privileged actions.
- Clear UI: compact, skimmable output inspired by Codex CLI.

System Overview
- CLI Entry: `dev.kit` as the only interface for users and AI clients.
- State Home: `~/.udx/dev.kit/` for config, logs, and local state.
- Knowledge Layer: local docs, module metadata, and UDX tooling references.
- Execution Layer: local tools or UDX Worker container as the default executor.
- AI Layer: prompt normalization, pipeline generation, and single-shot content.

Config Model (Two Tiers)
1) Capabilities (Supported/Available)
   - Static or detected info about what can be used.
   - Examples: `engines.docker.available`, `engines.ai.codex.detected`.
2) Features (Enabled/Configured)
   - User choices and values for how features run.
   - Examples: `ai.enabled`, `ai.rules_path`, `worker.enabled`.
   - Permissions and compatibility settings live here.

Config Requirements
- All values live in user-managed config files.
- Scripts only read config; no hidden defaults beyond schema defaults.
- Safe updates: write to new file then replace to avoid corruption.
- Visible change logs for configuration mutations.

Config and Workflows as Code
- Applies to all dev.kit modules and integrations.
- Global defaults live under `src/context/20_config/` (shared behavior).
- Module-specific overrides live under `src/context/30_module/<domain>/<module>/`.
- Merging rules: defaults first, then module-specific overrides, last-write wins.

Permissions and Safety
- Destructive actions must be explicit and confirmed.
- Secret detection only suggests storage or redaction, never auto-moves.
- Capture logs is opt-in and always easy to clear.

Related Design Docs
- Roadmap and phases: `src/context/20_config/development/roadmap.md`
- AI integration: `src/context/20_config/ai/overview.md`
- UX and output format: `src/context/20_config/user-experience/cli-output.md`
- Standards: `src/context/20_config/standards/development-standards.md`
- Docs structure: `src/context/20_config/development/docs-structure.md`
