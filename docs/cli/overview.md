# CLI

## Scope

Documents the dev.kit CLI surface and how commands are wired.

## Entry Points

- `bin/dev-kit`: high-level entrypoint. Loads helpers and dispatches subcommands from `lib/commands`.
- `bin/env/dev-kit.sh`: shell init (banner, capture hook, completions).
- `bin/scripts/install.sh`: install symlink, env, and completions.
- `bin/scripts/uninstall.sh`: remove symlink; `--purge` removes engine dir.
- `bin/completions/*`: bash and zsh completions.

## Command Dispatch

`bin/dev-kit` loads `lib/commands/*.sh`. Add a new command by creating
`lib/commands/<name>.sh` with a `dev_kit_cmd_<name>()` function.

## Capture Commands

Config:
- `capture.mode = global|repo|off` (default: `global`)
- `capture.dir = <path>` (optional override for global)

Notes:
- Relative `capture.dir` paths resolve under `DEV_KIT_HOME`.
- Capture commands do not update capture logs (safe to inspect last run).

Commands:
- `dev.kit capture path` (print capture directory)
- `dev.kit capture show` (print capture paths + last input/output)

## Context Commands

Config:
- `context.enabled = true|false` (default: `true`)
- `context.dir = <path>` (optional override)
- `context.max_bytes = 12000` (default)

Commands:
- `dev.kit context path` (print context file path)
- `dev.kit context show` (print context file contents)
- `dev.kit context reset` (clear context)
- `dev.kit context compact` (trim context to max bytes)
- `dev.kit exec --no-context` (run without reading/writing context)

## Codex Commands

- `dev.kit codex status` (show managed paths and last backup)
- `dev.kit codex apply` (backup and apply shared AI data to `~/.codex`)
- `dev.kit codex config --plan --path=<path>` (render planned config/skills)
- `dev.kit codex compare --path=<path>` (compare planned output vs `~/.codex/<path>`)
- `dev.kit codex restore` (restore the latest backup)

## Constraints

- Keep `bin/` minimal: entrypoints and shell wiring only.
- Subcommands live in `lib/commands/` and are discovered dynamically.
- Avoid hardcoded subcommand lists in bin or completions.
