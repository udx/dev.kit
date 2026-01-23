Capture Logs (dev.kit)

Purpose
- Capture your dev.kit terminal commands for review.
- Optionally capture full stdout/stderr via a subshell.

Defaults (config.env)
- `capture.enabled=true`
- `capture.full=true`
- `capture.auto_clean=true` (clears previous log on next captured command)
- `capture.auto_clean_iteration=true` (clears on each dev.kit command)
- `capture.ttl_days_global=3`
- `capture.ttl_days_repo=3`

Commands
- `dev.kit capture start` (starts full capture shell by default)
- `dev.kit capture start --no-shell` (full mode without auto shell)
- `dev.kit capture start --input` (commands only)
- `dev.kit capture show` (tail + auto-clean)
- `dev.kit capture shell` (full stdout/stderr)
- `dev.kit capture clear [--force]`
- `dev.kit capture auto-clean on|off`

Notes
- Full capture uses `script` and writes to `<repo>/.udx/dev.kit/capture/capture.log`.
- Command-only capture logs to `<repo>/.udx/dev.kit/capture/capture.log`.
- If `CODEX_SESSION_ID` is set, the filename becomes `capture.<session>.log`.
- Only `dev.kit` commands are captured by default.
- Repo contexts are stored under `<repo>/.udx/dev.kit/<module>/`.
