---
name: devkit-install-cleanup
description: Install, configure, validate, uninstall, and clean up dev.kit on the host (includes Codex integration checks).
---

# dev.kit Install & Cleanup

Use this skill when you need to install dev.kit, perform initial configuration, validate the setup, or uninstall and clean up a host environment.

## Preflight

- Confirm repo root and current branch.
- Capture current state:
  - `dev.kit paths`
  - `dev.kit doctor`

## Install

Prefer the built-in command:
- `dev.kit install`

Fallback (if needed):
- `bin/scripts/install.sh`

## Enable shell integration

- `dev.kit enable --shell=bash` or `dev.kit enable --shell=zsh`
- If you need to revert later, remove the `source ".../dev.kit.sh"` line from the shell profile.

## Validate

- `dev.kit doctor`
- Dev-mode test suite:
  - `dev.kit test install --run --force`
  - With purge: `DEV_KIT_TEST_PURGE=true dev.kit test install --run --force`
- If Codex rules were changed:
  - `dev.kit codex rules --plan`
  - `dev.kit codex rules --apply`
  - `codex execpolicy check ~/.codex/rules/default.rules`

## Uninstall

- `dev.kit uninstall`
- To remove engine state/config:
  - `dev.kit uninstall --purge`

## Cleanup checklist

- Remove shell profile `source` line if still present.
- Verify binaries are removed:
  - `command -v dev.kit`
- Verify engine dir state:
  - `ls -la ~/.udx/dev.kit`

## Experience log

- Record results in `src/context/20_config/experience/` using the session summary template.
- Reusable test harness: `bin/scripts/ux-check.sh` (wraps `dev.kit test install`, set `DEV_KIT_UX_*` env vars to customize).
