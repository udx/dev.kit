# dev.kit

Team: Dmytro Smirnov (Human) + Codex CLI (AI)
Repo: udx/dev.kit
Standard: Context-Driven Engineering (CDE)

## Team Context

- Dmytro Smirnov (Human): Software Engineer focused on DevSecOps, automation, and cybersecurity.
- Codex CLI (AI): AI coding agent used as a collaborative implementation and refactoring partner.

## Repository Context

- Local engineering kit to bootstrap and orchestrate developer workflows.
- Bash-first CLI with minimal dependencies and user-confirmed integration.
- Built to be a middleware layer for AI CLIs (Codex, Claude) to discover and use local tooling safely.

## Design Context: Local Bootstrap + Safe Integration

Objective: Make local developer workflows reproducible, discoverable, and safe to automate without heavy shell edits.

Design characteristics:
- Minimal bootstrap: install copies env/config files into `~/.udx/dev.kit/`.
- Explicit enablement: user confirmation before modifying shell profiles.
- Session init is lightweight and configurable (`config.env`).
- Integrations are suggested, not forced (Codex/Claude detection is advisory).

## Delivery Model: Bash-First, Incremental Features

Operational model:
- Core CLI is a small bash script; heavy logic lives in modules.
- Configuration is flat key/value (`config.env`) to avoid extra parsers.
- Install/uninstall are explicit and reversible.

## Iteration Protocol (Design-First)

Loop used throughout:
1. Capture expected behavior in `details.md` (TDD-style snapshot).
2. Align README and module stubs to the design.
3. Implement thin routing and module scaffolding.
4. Expand functionality with reviewable increments.

## Collaboration Workflow (Human + Codex)

- Start with design expectations before code changes.
- Keep flow guidance user-friendly and non-disruptive.
- Prefer minimal dependencies; add tools only when needed.
- Track integrations and permissions via config.

## Examples of Applied Practice

- Install script places env/config into `~/.udx/dev.kit/`.
- Enable flow appends a single `source` line with confirmation.
- Session init prints a small “dev.kit: active” notice unless quiet mode.

## Recent Iteration (Summary)

- Refactored layout: modules in `bin/modules`, scripts in `bin/scripts`, env in `bin/env`.
- Added shell autocomplete for dev.kit (bash/zsh).
- Implemented capture with repo-scoped context under `.udx/dev.kit/<module>/`.
- Consolidated docs, guides, and experience logs under `docs/`.
- Added context registry helper for future cleanup automation.

## Next Extensions (Planned)

- Module router: `dev.kit <module> ...` with `lib/<module>.sh` handlers.
- Codex/Claude integrations: discover, suggest, and apply rules via dev.kit.
- Worker helpers for local execution and deployment flows.
- Update command (`dev.kit update`) for git-based installs.
