# dev.kit install/cleanup (experience log)

Goal
- Validate install, initial config, and uninstall/cleanup flow on a host.

Scope
- `dev.kit install` and `dev.kit uninstall --purge`
- Shell enable/disable (manual removal of `source` line)
- Codex rules plan/apply + execpolicy check

Notes
- This log captures the expected checklist; run the workflow and append results.
- Reusable harness: `bin/scripts/ux-check.sh` (wraps `dev.kit test install`, writes to `tmp/ux/` by default).
- Use the session summary template if a longer record is needed.
