# Repo Cleanup Report — Spec Kernel First

Date: 2025-02-14
Scope: repo hygiene and entry-point clarity (no behavior changes)

## A) Confusion / Duplication Risks
- `README.md` referenced `docs/` paths that do not exist; actual spec kernel lives under `docs/`.
- Legacy runtime tree overlaps with current runtime tree: legacy `bin`, `lib`, `src`, `config` vs `bin/`, `lib/`, `src/`, `config/`.
- Legacy test/fixture/tmp structure may be mistaken as active: legacy `fixtures`, `test`, `tmp`.
- Mixed doc locations can obscure ownership: legacy README vs `docs/**`.

## B) Intended Top-Level Story
| Area | Meaning |
| --- | --- |
| `bin/` | Product runtime CLI entrypoints (current). |
| `lib/` | Product runtime library code (current). |
| `src/` | Product runtime source (current). |
| `config/` | Product runtime configuration (current). |
| `docs/` | Spec kernel: design, contracts, and canonical repo interfaces. |
| `scripts/` | Iteration tooling (review/apply helpers). |
| `prompts/` | Iteration prompts and review inputs. |
| `skills/` | Iteration skill contracts and workflow specs. |
| legacy tree | Legacy tree (archived prior layout and artifacts; preserved). |

## C) Cleanup Actions Taken
- Updated root entrypoint links to spec kernel and iteration loop.
- Added explicit iteration entrypoint in README.
- Added explicit legacy pointer in README.

## D) What Did Not Change
- No runtime code paths were modified (`bin/`, `lib/`, `src/`, `config/`).
- No legacy content was moved or removed (legacy tree contents).
- No spec kernel content was rewritten (`docs/**`).
- No scripts or prompts were modified (`scripts/**`, `prompts/**`).

## E) Open Questions / Follow-Ups (max 5)
1) Should a single top-level `docs/` shim be added to redirect to `docs/`?
2) Should the legacy README include a brief banner pointing back to `docs/index.md`?
3) Do we want a lightweight `fixtures/` or `test/` directory in the current tree to avoid confusion with the legacy tree?
4) Is there a canonical list of “current” runtime entrypoints that should be indexed in `docs/runtime/`?
5) Are there generated logs or tmp paths to add to `.gitignore` beyond `.udx/` and `.dev.kit/`?

## F) Next Implementation Milestone
Minimal steps to implement DOC-002 and DOC-003:
- Define DOC-002 scope and create the spec file in `docs/` with versioning rules aligned to CDE contracts.
- Define DOC-003 scope and create the spec file in `docs/` with explicit inputs/outputs and forbidden behaviors.
- Update `docs/index.md` and any relevant domain indexes to link DOC-002 and DOC-003.
- Add workflow entries to `docs/_feedback.md` for DOC-002 and DOC-003 with clear acceptance criteria.

Minimal steps to begin CLI MVP aligned with `execution/cli-primitives.md`:
- Draft a minimal command map in `docs/runtime/` that binds each CLI primitive to a runtime responsibility.
- Create a thin `bin/` entrypoint stub that validates inputs and emits normalized outputs per the primitives spec (no side effects beyond logging).
- Add a repo-local validation checklist in `docs/execution/` that defines how to prove primitive compliance.
- Ensure iteration loop artifacts (review → workflow → apply → validate → log) reference the CLI primitive names verbatim.

## G) Change Log (Auditable)
- Updated `README.md` to point to `docs/index.md` and `docs/execution/iteration-loop.md` and to surface iteration and legacy entrypoints.
- Added `docs/_repo-cleanup.md` (this report).
