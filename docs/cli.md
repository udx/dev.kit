# Domain: CLI

## Scope
This section documents the dev.kit CLI surface and how the repository is wired.

## Structure
- `bin/dev-kit`: High-level entrypoint. Loads core helpers and dispatches subcommands dynamically from `lib/commands`.
- `bin/env/dev-kit.sh`: Shell init (banner, capture hook, completions).
Capture storage (config):
- `capture.mode = global|repo|off` (default: `global`)
- `capture.dir = <path>` (optional override for global)
Relative `capture.dir` paths resolve under `DEV_KIT_HOME`.
Capture commands:
- `dev.kit capture path` (print capture directory)
- `dev.kit capture show` (print capture paths + last input/output)
Capture commands do not update capture logs (so you can inspect the last run).
Codex integration commands:
- `dev.kit codex status` (show managed paths and last backup)
- `dev.kit codex apply` (backup and apply shared `src/ai/data` + `src/ai/integrations/codex` to `~/.codex`)
- `dev.kit codex config --plan --path=<path>` (render planned config/skills from src/ai/data + src/ai/integrations/codex)
- `dev.kit codex compare --path=<path>` (compare planned output vs `~/.codex/<path>`)
- `dev.kit codex restore` (restore the latest backup)
- `bin/completions/*`: Shell completions (bash + zsh).
- `bin/scripts/install.sh`: Install symlink + env + completions.
- `bin/env/dev-kit.sh`: Shell init (manual `source` or profile).
- `bin/scripts/uninstall.sh`: Remove symlink; `--purge` removes engine dir.
- `lib/commands/*.sh`: Subcommand implementations (dynamic dispatch).
- `lib/ui.sh`: Shared UI helpers for bin + scripts.

## Dispatch model
`bin/dev-kit` lists and loads `lib/commands/*.sh`. Any new command is added by creating
`lib/commands/<name>.sh` with a `dev_kit_cmd_<name>()` function.

## Constraints
- `bin/` stays minimal: only entrypoints and shell wiring.
- Subcommands live in `lib/commands/` and are discovered dynamically.
- No hardcoded subcommand lists in bin or completions.
