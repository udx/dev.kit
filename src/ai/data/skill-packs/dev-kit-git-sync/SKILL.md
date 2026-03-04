---
name: dev-kit-git-sync
description: Logical commit and synchronization skill. Identifies repository drift and groups changes into domain-specific logical commits (docs, ai, cli, core, misc). Use this skill to resolve state divergence after completing a task or iteration.
---

## Objective
Normalize and resolve repository drift by performing logical, atomic commits based on local state and task context.

## Success-First UX Contract
- **Identify Drift**: Automatically detect staged, unstaged, and untracked changes.
- **Group Logically**: Categorize files into `docs`, `ai`, `cli`, `core`, and `misc`.
- **Dry-Run Mode**: Always allow previewing the commit groups before execution.
- **Task Context**: Associate commits with a `task_id` for traceability.

## Input Contract
Required:
- `task_id`: The ID of the current task (e.g., DOC-001).

Optional:
- `dry_run`: `true|false` (default: `false`).
- `message`: Optional base message prefix for commits.

## Workflow
1. Run `src/ai/data/skill-packs/dev-kit-git-sync/scripts/git_sync.sh`.
2. Review the logical groupings and proposed commit messages.
3. If `dry_run=false`, execute the commits.
4. Return a summary report of the resolution.

---
_UDX DevSecOps Team_
