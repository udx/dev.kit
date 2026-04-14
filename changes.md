# Changes

### 0.2.0

- npm release workflow with OIDC provenance via `udx/reusable-workflows`
- GitHub releases created automatically on merge to main
- `dev.kit --version` flag
- Copilot review feedback fixes (JSON escaping, cache multi-line values, fixture portability)

### 0.1.0

Initial release.

- `dev.kit repo` — analyse repo structure, archetype detection, gap reporting, scaffold generation
- `dev.kit agent` — generate agent context (AGENTS.md + `.rabbit/context.yaml`) from repo signals
- `dev.kit learn` — multi-source lesson extraction from Claude, Codex, and Copilot sessions
- YAML config catalog for detection signals, archetype rules, scaffold templates, and workflows
- JSON output (`--json`) for all commands
- Shell completions (bash + zsh)
- Install/uninstall scripts
- Test suite with fixture repos (docker, wordpress, shell, php, workflow)
