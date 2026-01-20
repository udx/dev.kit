### Why devs need it
- A friendly, consistent entrypoint for local workflows.
- Lower setup friction while keeping changes explicit and reversible.
- Make tooling discoverable and safe to automate.
- Encourage deterministic, reviewable paths for humans and AI.

### User experience
- One-line install.
- Minimal and explicit shell integration (opt-in).
- Clear next-step guidance after each action.
- Feature discovery that works with or without AI CLI support.

### AI integration
- dev.kit provides normalized context and safe entrypoints for AI CLIs.
- Integrations are optional and should never block basic usage.
- When AI is enabled, dev.kit can dynamically manage feature guidance (reduce redundant tips).
- Before changing AI context or rules, suggest exploring and reviewing existing configuration.
- Guidance can be manual: users may direct Codex/Claude to dev.kit features without auto-integration.

## Core Workflow

1) `dev.kit install`
   - Creates `~/.udx/dev.kit/`
   - Copies `bin/env/dev-kit.sh` -> `~/.udx/dev.kit/env.sh`
   - Copies `config/default.env` -> `~/.udx/dev.kit/config.env` if missing
   - Guidance: prints the next suggested step (enable or config)
   - Supports one-line install (public script)

2) `dev.kit enable --shell=bash|zsh`
   - Appends: `source ~/.udx/dev.kit/env.sh`
   - Requires confirmation; provides manual copy/paste fallback
   - Guidance: suggests running a new shell or sourcing `env.sh` once

3) New shell session
   - `env.sh` runs `dev.kit init` (quiet if configured)
   - `dev.kit init` prints a short notice: `dev.kit: active`
   - `dev.kit init` reads `~/.udx/dev.kit/config.env` and suggests integrations
   - Guidance: if no integrations detected, suggest exploring modules

## Session Notice

- Default notice is `dev.kit: active` on each new session
- Suppressed when `quiet=true`

## Module Architecture (CDE-style assets)

Each module is a small, self-contained unit with separate assets:
- `bin/modules/<name>/index.sh` — execution/logic
- `bin/modules/<name>/schema.yml` — configuration and metadata (12-factor style)
- `bin/modules/<name>/doc.md` — human-readable docs and examples

This keeps code, config, and documentation distinct while still integrated.

### Planned modules and base functions
- `codex`: detect Codex CLI, show rules/config locations, preview/apply rules templates
- `claude`: detect CLI, show config path, suggest enablement
- `worker`: detect worker tools, summarize worker config paths
- `logging`: log helpers with levels and optional file target
- `git`: common repo helpers (status, branch, clean-check)

## Integrations Detection (User Experience)

- Detect installed tools and surface a short, actionable next step:
  - docker: executable units, local SDLC tests, deployment scripts
  - npm: UDX tool CLIs and JS-based workflows
  - git: repo history manipulation, workflow generation helpers
  - gh: GitHub API access (requires token)
- Detection should guide, not block; integrations are opt-in.
- Critical actions must require explore/review suggestions and warnings.

## Flow Examples (Brief)

- Install -> enable -> new session auto-init with `dev.kit: active`
- Codex detected -> suggest enabling codex integration
- Worker tooling detected -> suggest worker module usage

## Config (`config.env`)

- Flat `key=value` only
- Initial keys: `quiet`, `codex_suggest`
- Presets: offer a minimal preset and an expanded preset for power users

## Product Intent (Clarifying Summary)

- dev.kit is a local developer CLI that empowers AI CLIs (Codex/Claude) with UDX tooling.
- UDX tooling is repo-centric and self-explanatory (CLI-driven) and aligns with CDE.
- Design principles: low dependency, safe-by-default, opt-in integration, reviewable changes.

## Implementation Details (AI Integration + Testing)

- AI integrations should be tested with prompt-driven harnesses (e.g., promptfoo).
- dev.kit should expose deterministic outputs for tests (no side effects without flags).

## Feedback and Context Notes

- Each step should guide what to do next; if finished, guide to other areas.
- Basic config options (presets) first, with a path to a full config.
- Main feature: configure AI CLIs and suggest dev.kit context + workflow rules.
- dev.kit is a local CLI that empowers AI with UDX tooling and CDE principles.

## Development Tenets (Design Use)

The dev.kit design must align with these principles:
- TDD-first: define expected behavior before implementation.
- Small steps: iterate in minimal, reviewable changes with tight feedback loops.
- Manual before automation: do it by hand, then test, then automate.
- Experience capture: convert successful work into reusable docs and assets.
- Host-agnostic: prefer Docker/containers for consistent execution.
- Daily hygiene: visible status, frequent pushes, and end-of-day gates.
