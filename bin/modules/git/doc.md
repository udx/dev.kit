Git Module (v2)

Purpose
- Provide safe-by-default git helpers and best practices.
- Offer common workflows as repeatable command recipes.

Quick Commands
- Remove latest unpushed commits:
  - `git reset --soft HEAD~1` (keep staged)
  - `git reset --mixed HEAD~1` (keep working tree)
  - `git reset --hard HEAD~1` (discard changes)
- Cleanup history before PR:
  - `git branch backup/cleanup-$(date +%Y%m%d)`
  - `git fetch origin && git rebase -i origin/main`
  - `git push --force-with-lease`

Notes
- Always verify commits are unpushed before using reset.
- Prefer `--force-with-lease` when rewriting remote history.
- Keep iterations small and reversible.
- See `docs/src/configs/principles/development-tenets.md` for workflow norms.
