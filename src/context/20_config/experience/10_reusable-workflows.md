# Reusable Workflows CLI

Team: Dmytro Smirnov (Human) + Codex CLI (AI)
Repo: udx/reusable-workflows
Standard: Context-Driven Engineering (CDE)

## Team Context

- Dmytro Smirnov (Human): Software Engineer focused on DevSecOps, automation, and cybersecurity.
- Codex CLI (AI): AI coding agent used as a collaborative implementation and refactoring partner.

## Repository Context

- Reusable GitHub Actions workflows with a CLI that generates workflow manifests.
- Templates are defined by three assets: `.github/workflows/*.yml`, `docs/*.md`, and `examples/*.yml`.
- CLI is packaged for global use and is test-driven.
- Repo aligns with the CDE `workflow_templates` schema.

## Design Context: Repo-Centric, Metadata-Integrated

Objective: Build a single unit of execution that is friendly to humans, automation, and AI agents, while eliminating hardcoded workflow knowledge.

Design characteristics:
- Metadata is embedded in the assets themselves (definition, docs, example), not stored in separate config files.
- The CLI derives its UI, prompts, presets, and output strictly from those assets.
- Outputs are deterministic and validated via tests (manifest generation is a contract).
- Documentation is executable and template-driven, not a static appendix.

Concrete design decisions:
- Presets are parsed from `examples/*.yml` to represent real-world configurations.
- The custom flow selects registries and prompts only for inputs not defined by defaults or presets.
- Setup guides are rendered from `cli/templates/setup/{template}.hbs`, keeping structure configurable per template.

## Delivery Model: 12-Factor, AI-Friendly

Operational model:
- Config is externalized and lives in repo assets (vars/secrets placeholders in examples).
- The CLI is a single entrypoint for humans, CI/CD, and AI agents.
- The same assets power interactive and non-interactive flows.
- Tests are stored as data (JSON + expected manifests) to keep behavior externalized.

## Iteration Protocol (TDD + Review)

Loop used throughout:
1. Define expected output in tests (manifest as the contract).
2. Implement minimal code changes to satisfy tests.
3. Validate in interactive UX, then refine prompt flow.
4. Refactor only after tests are green.

This kept repository changes deliberate, reversible, and observable.

## Collaboration Workflow (Human + Codex)

- Scope first: slice work by modular boundaries, define the test for that slice, then iterate.
- Tests drive decisions: define expected output, implement minimal logic, run tests, refactor only after green.
- Feedback loop: review UX logs, adjust prompts, re-run tests.
- Strict separation: assets define configuration; code only reads and applies.
- Safety: remove temp artifacts, avoid editing template sources during generation, keep changes reviewable.

### Cadence Snapshot

- Test runs: `npm test` (CLI unit tests) and `bash ci/scripts/test-cli-ux.sh` (UX suite).
- Deliverables: setup template, JSON-only UX tests, CI script relocation.
- Commits: multiple logical commits grouped by feature/test/ops changes.

### Operational Configuration (Useful Only)

- Environment: CLI runs in a sandboxed environment; write operations and certain test runs require explicit approval.
- Determinism: UX testing is deterministic via `--test-input` JSON and expected manifest fixtures.
- Asset integrity: templates are loaded from `.github/workflows`, `docs`, `examples`; CLI has no hardcoded workflow logic.
- CI scripts centralized in `ci/scripts/` and referenced consistently across docs and workflows.

## Examples of Applied Practice

- JSON-driven UX tests: `cli/test/*-tests.json` + `cli/test/expected/`.
- Preset discovery from examples, not code branches.
- Deterministic CLI runs via `--test-input` to reproduce interactive paths.
- Setup documentation rendered from templates, not string builders.
- CLI-only templates (`cli/templates/setup`) to avoid mixing repo assets.

## CDE Alignment (Three Layers)

1. Software source specific standard (build/human):
   - Clear CLI UX, structured docs, deterministic assets.
2. 12-factor GitHub repo standard (deployment/program):
   - Config externalized, workflows as declarative units, single CLI entrypoint.
3. Context-Driven Engineering (active context layer/AI):
   - Metadata embedded in source assets, no AI guesswork, predictable outputs.

## Operational Practices

- Run CLI in fixture repos, not in template source repos.
- Keep presets in examples as the source of truth.
- Push prompt behavior to explicit state (e.g., registry selection cannot be empty without confirmation).
- Keep docs executable and data-driven.

## Next Extensions (Planned)

- Add setup templates for remaining workflows.
- Expand UX tests to cover custom flows and edge cases.
- Extend the CDE schema to recognize setup templates as first-class assets.

## End Word

You’re welcome—great work today. Sleep well, and we’ll pick up tomorrow.

To continue this session, run codex resume 019bccb9-64cf-7d91-bec0-eff0bab69eff

> Token usage: 
> - total=624,828 
> - input=537,128 
> - (+ 26,286,208 cached) 
> - output=87,700 
> - (reasoning 43,136)
