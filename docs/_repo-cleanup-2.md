# Repo Cleanup Report — Iteration 2

Date: 2026-01-26
Scope: repo hygiene and navigation clarity (no behavior changes)

## What Changed
- Canonicalized skills under `skills/` and moved `workflow-generator` into that path.
- Added shims: `docs/README.md` and `skills/README.md`.
- Linked entry points across `README.md`, `docs/index.md`, `docs/execution/iteration-loop.md`, and `skills/iteration.md`.
- Added a Repo Map section to `README.md`.
- Normalized generated-output ignores in `.gitignore`.

## What Did Not Change
- No runtime code paths were modified (`bin/`, `lib/`, `src/`, `config/`).
- No legacy content was removed or altered (legacy tree contents).
- No spec kernel contracts were rewritten (`docs/**`).
- No scripts or prompts were modified (`scripts/**`, `prompts/**`).

## Skills Canonicalization Rationale
Canonical location is `skills/` because the iteration loop already references
`skills/iteration.md`, the root README is a primary entrypoint, and keeping
skills adjacent to other top-level entrypoints minimizes cross-tree ambiguity.
`skills/` is the canonical path.

## Updated Repo Map
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

## Follow-Ups (Max 5)
1) Confirm whether `assets/fixtures/` should remain tracked or be fully treated as generated output.
2) Consider a brief banner in the legacy README pointing back to `docs/index.md`.
3) Decide whether `docs/README.md` should include a short policy on avoiding duplicated spec content.

## Exact Change List

Moved:
- `skills/workflow-generator/SKILL.md` → `skills/workflow-generator/SKILL.md`
- `skills/workflow-generator/references/prompt-as-workflow-approach.md` → `skills/workflow-generator/references/prompt-as-workflow-approach.md`

Created:
- `docs/README.md`
- `skills/README.md`
- `docs/_repo-cleanup-2.md`

Updated:
- `.gitignore`
- `README.md`
- `docs/index.md`
- `docs/execution/iteration-loop.md`
- `skills/iteration.md`

## Appendix — Legacy Salvage (2025-03-08)
- Legacy salvage executed: copied KEEP items into canonical locations and prepared legacy tree for retirement.
- See `docs/legacy-salvage-plan.md` and `docs/legacy-retirement.md` for audit details.
