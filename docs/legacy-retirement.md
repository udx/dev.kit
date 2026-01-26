# Legacy Retirement Report

Date: 2025-03-08
Scope: legacy tree retirement and reference cleanup

## Salvaged (Copied to Canonical Locations)
- `assets/legacy/` (workflow/UX SVGs)
- `bin/modules/capture/`
- `bin/modules/git/`
- `bin/modules/session/`
- `bin/scripts/test-cli.sh`
- `bin/scripts/ux-check.sh`
- `assets/fixtures/default.rules`
- `lib/modules/codex.sh`
- `lib/modules/workflow.sh`
- `templates/docker/`
- `templates/mermaid/`
- `schemas/legacy/`
- `schemas/legacy/modules/`
- `docs/specs/module.md`

## Archived (Left in Legacy Graveyard)
- Legacy docs, fixtures, tests, and legacy runtime duplicates preserved for history.

## References Eliminated
Updated to remove direct legacy-root references and point to canonical locations or neutral wording:
- `README.md`
- `docs/_repo-cleanup.md`
- `docs/_repo-cleanup-2.md`
- `docs/legacy-salvage-plan.md` (normalized legacy path notation)

Search summary:
- String search for the legacy root path with trailing slash returns zero matches.

## Retirement Action Taken
- Moved legacy tree contents into the legacy graveyard at `_graveyard/2025-03-08` within the legacy root.

## Rollback Instructions
1) Move items from the legacy graveyard back to the legacy root (reverse the 2025-03-08 move).
2) If needed, remove copied KEEP items from canonical locations listed above.
3) Restore any legacy references in docs if you re-enable legacy paths.
