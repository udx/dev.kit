# Domain: CLI

## Scope
This section documents the dev.kit CLI surface and how the repository is wired.

## Structure
- `bin/dev-kit`: High-level entrypoint. Loads core helpers and dispatches subcommands dynamically from `lib/commands`.
- `bin/env/dev-kit.sh`: Shell init (banner, capture hook, completions).
- `bin/completions/*`: Shell completions (bash + zsh).
- `bin/scripts/install.sh`: Install symlink + env + completions.
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
