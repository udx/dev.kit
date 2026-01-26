# Legacy Salvage Plan

Date: 2025-03-08
Scope: legacy tree (removed) plus references elsewhere

## Phase 1 — Inventory and Classification

| Legacy path/group (under legacy root) | Class | Why | Proposed destination (KEEP only) |
| --- | --- | --- | --- |
| `README.md`, `details.md`, `layers.md` | ARCHIVE | Legacy writeups superseded by `docs` | — |
| `assets/*.svg` | KEEP | Unique workflow/UX diagrams not present elsewhere | `assets/legacy/` |
| `bin/dev-kit` | ARCHIVE | Duplicate of `bin/dev-kit` | — |
| `bin/env/dev-kit.sh` | ARCHIVE | Duplicate of `bin/env/dev-kit.sh` | — |
| `bin/completions/dev.kit.bash`, `bin/completions/_dev.kit` | ARCHIVE | Duplicate of `bin/completions/*` | — |
| `bin/modules/codex/*` | ARCHIVE | Duplicate of `bin/modules/codex/*` | — |
| `bin/modules/capture/*` | KEEP | Module absent from current runtime | `bin/modules/capture/` |
| `bin/modules/git/*` | KEEP | Module absent from current runtime | `bin/modules/git/` |
| `bin/modules/session/*` | KEEP | Module absent from current runtime | `bin/modules/session/` |
| `bin/modules/legacy` | ARCHIVE | Explicitly marked legacy module utilities | — |
| `bin/scripts/install.sh`, `bin/scripts/update.sh`, `bin/scripts/uninstall.sh` | ARCHIVE | Duplicates of `bin/scripts/*` | — |
| `bin/scripts/test-cli.sh`, `bin/scripts/ux-check.sh` | KEEP | Scripts absent from current runtime | `bin/scripts/` |
| `config/*.env` | ARCHIVE | Duplicates of `config/*.env` | — |
| `default.rules` | KEEP | Useful Codex execpolicy template not present elsewhere | `assets/fixtures/default.rules` |
| `fixtures/**` | ARCHIVE | Historical fixtures and context archives | — |
| `lib/context.sh`, `lib/logging.sh`, `lib/module.sh`, `lib/ui.sh` | ARCHIVE | Duplicates of `lib/*` | — |
| `lib/modules/codex.sh` | KEEP | Module absent from current runtime | `lib/modules/codex.sh` |
| `lib/modules/workflow.sh` | KEEP | Module absent from current runtime | `lib/modules/workflow.sh` |
| `lib/templates/docker/*` | KEEP | Unique docker templates | `templates/docker/` |
| `lib/templates/mermaid/*.mmd` | KEEP | Unique mermaid templates | `templates/mermaid/` |
| `public/schema/*.json` | KEEP | Legacy schema refs not present elsewhere | `schemas/legacy/` |
| `public/modules/**` | KEEP | Legacy module metadata not present elsewhere | `schemas/legacy/modules/` |
| `src/schema/module.md` | KEEP | Unique module schema doc | `docs/specs/module.md` |
| `src/context/**` | ARCHIVE | Historical docs superseded by `docs` | — |
| `test/**` | ARCHIVE | Historical test artifacts (not generated tmp) | — |
| `tmp/**` | TRASH | Temporary outputs | — |

## Phase 2 — Deduplication Check (Current vs Legacy)

| KEEP candidate (under legacy root) | Duplicate? | Already exists at | Port diff notes |
| --- | --- | --- | --- |
| `assets/*.svg` | No | — | — |
| `bin/modules/capture/*` | No | — | — |
| `bin/modules/git/*` | No | — | — |
| `bin/modules/session/*` | No | — | — |
| `bin/scripts/test-cli.sh` | No | — | — |
| `bin/scripts/ux-check.sh` | No | — | — |
| `default.rules` | No | — | — |
| `lib/modules/codex.sh` | No | — | — |
| `lib/modules/workflow.sh` | No | — | — |
| `lib/templates/docker/*` | No | — | — |
| `lib/templates/mermaid/*.mmd` | No | — | — |
| `public/schema/*.json` | No | — | — |
| `public/modules/**` | No | — | — |
| `src/schema/module.md` | No | — | — |
