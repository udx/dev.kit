---
name: devkit-install-cleanup
description: Install, configure, validate, uninstall, and clean up dev.kit on the host.
---

# dev.kit Install & Cleanup

Goal
- Install dev.kit, validate the setup, and cleanly uninstall with optional purge.

Scope
- Host install, shell enablement, validation, uninstall, and cleanup.

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

## Notes

- Reusable test harness: `bin/scripts/ux-check.sh` (wraps `dev.kit test install`, set `DEV_KIT_UX_*` env vars to customize).
