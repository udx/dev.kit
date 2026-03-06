---
name: dev-kit-git-sync
description: MANDATORY skill for logical repository synchronization and atomic commits. Categorizes changes into domain-specific groups (docs, ai, cli, core, misc) and generates high-fidelity commit messages. Use this skill to resolve state divergence after completing a task or iteration.
---

## Objective
Normalize and resolve repository drift by performing logical, atomic commits based on local state and task context.

## CLI Usage Example
```bash
# Sync changes for a documentation task (dry-run first)
dev.kit sync --dry-run --task-id "DOC-123"

# Perform logical commits for a completed feature
dev.kit sync --task-id "CLI-456"

# Or resolve intent directly (Dynamic Normalization)
dev.kit skills run "git-sync" "Resolve repo drift for task CLI-456"
```

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
1. Call `dev.kit sync` with the desired options.
2. Review the logical groupings and proposed commit messages.
3. If `dry_run=false`, execute the commits.
4. Return a summary report of the resolution.

---
_UDX DevSecOps Team_
