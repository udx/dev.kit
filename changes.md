# Changes

### 0.3.0

- Restructure AGENTS.md as a deterministic execution contract with layered sections
- Add 7 contract rules: no scanning, strict boundaries, manifests before code, context over memory, verify locally, follow workflow, reuse over invention
- Add GitHub context layer to `context.yaml` — open issues, recent PRs, security alerts via `gh api`
- Add 10 engineering practices from lessons learned: context-over-memory, manifests-before-code, reuse-over-invention, localhost-first, delivery-chain-traceability, structured-outcome-reporting, docs-first-alignment, config-over-code, legacy-reduction, verification-scope
- Add learning workflow patterns: docs-first-alignment, workflow-tracing, verification-scope, legacy-reduction, agent-handoff
- Enrich knowledge-base.yaml with GitHub as a context source
- Strengthen post-merge close-out reporting (exact URLs, versions, deltas)
- Fix package name to `@udx/dev-kit` (matches npm registry)
- npm install support (`npm install -g @udx/dev-kit`)

### 0.2.1

- Fix release workflow trigger to match reusable-workflows pattern
- Add `workflow_dispatch` for manual re-triggers
- Enable OIDC provenance for npm publishing

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
