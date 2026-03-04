# CLI

## Entry Points

- `bin/dev-kit`: high-level entrypoint. Loads helpers and dispatches subcommands.
- `bin/env/dev-kit.sh`: shell init (banner, capture hook, completions).
- `bin/scripts/install.sh`: install symlink, env, and completions.

## Core Commands

### Status & Health
- `dev.kit status`: High-fidelity engineering brief.
- `dev.kit doctor`: Verify environment health and software detection.

### AI & Skills
- `dev.kit ai skills`: List managed repository powers with workflow metadata.
- `dev.kit ai commands`: Inspect CLI command keywords and waterfall steps.
- `dev.kit ai advisory`: Fetch engineering guidance from local documentation.
- `dev.kit agent <gemini|codex>`: Synchronize AI integrations and memories.

### Task & Execution
- `dev.kit task start --request "<intent>"`: Begin a context-tracked task.
- `dev.kit exec "<request>"`: Execute AI-powered requests with repo context.

## Support Commands

### Capture
- `dev.kit capture path`: Print capture directory.
- `dev.kit capture show`: Print last input/output logs.

### Context
- `dev.kit context show`: Print context file contents.
- `dev.kit context reset`: Clear repository-scoped context.

### Codex (Stage 1 Integration)
- `dev.kit codex config all --apply`: Synchronize managed Codex artifacts.
- `dev.kit codex compare --path=skills`: Compare local vs applied skill drift.

## Library Dispatch

`bin/dev-kit` dynamically loads `lib/commands/*.sh`. Subcommands are mapped to `dev_kit_cmd_<name>`.
