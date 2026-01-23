# Roadmap (v3)

Phases of Implementation
1) Install and config pipeline: minimal interaction, quick config, and each post-step suggests a dev.kit command for advanced config. Tests are defined first and are dynamic, using dev.kit output with a shared config schema used for core logic and tests.
2) AI integration for prompt execution and Codex rules/skills/config management. Designed to be flexible, scalable, and easy to manage, with Context7 or other MCP support.
3) Incremental development, fixes, and improvements.

MVP Scope
- Install and config pipeline (core).
- Engine detection and capability summary (core).
- AI integration rules and minimal config management (core).
- Prompt-to-pipeline contract (`dev.kit -p`) with JSON/text outputs.
- Minimal UI formatting and stable output structure.
- Rules template management for Codex/Claude/Gemini (core).

Future Modules (Post-MVP)
- Autocomplete for `dev.kit` and module prompts.
- Secure env manager with local keychain and remote secret providers.
- Shell startup pipeline with entrypoint hooks and cleanup actions.
- Workspace linting: detect TODOs, leftovers, and stale branches.
- Capture logs for AI context with scrub/preview.
- Timers and daily workflow reminders.

Open Questions
- Exact configuration file formats and location strategy.
- How to expose Context7 as a data source when AI is disabled.
- How to package and version rules across teams.
