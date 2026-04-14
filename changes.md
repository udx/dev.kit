# Changes

### 0.4.0

- Add structured dependency resolution with cross-repo tracing
- Resolve same-org dependencies via `gh api` and sibling directory lookup
- Track file-level relationships (`used_by`) mapping current repo files to their dependencies
- Trace 6 dependency sources: workflow reuse, Docker images, Compose images, versioned YAML configs, GitHub URLs, npm packages
- Add `--force` flag to `dev.kit repo` for full dependency re-resolution
- Include structured dependencies in JSON output (`repo.json`, `agent.json`)
- Render dependency relationships in AGENTS.md with resolved metadata and source file mappings
- Add `dependency_trace_compose_files` and `dependency_trace_url_globs` to detection-signals.yaml

### 0.3.0

- Restructure AGENTS.md as a deterministic execution contract with layered sections
- Add 8 contract rules: no scanning, strict boundaries, manifests before code, context over memory, verify locally, follow workflow, reuse over invention, remember context
- Add GitHub context layer to `context.yaml` — open issues, recent PRs, security alerts via `gh api`
- Add 10 engineering practices from lessons learned: context-over-memory, manifests-before-code, reuse-over-invention, localhost-first, delivery-chain-traceability, structured-outcome-reporting, docs-first-alignment, config-over-code, legacy-reduction, verification-scope
- Add learning workflow patterns: docs-first-alignment, workflow-tracing, verification-scope, legacy-reduction, agent-handoff
- Enrich knowledge-base.yaml with GitHub as a context source
- Strengthen post-merge close-out reporting (exact URLs, versions, deltas)
- Remove `--scaffold` flag (created empty stubs — gap reporting is the useful part)
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
