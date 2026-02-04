---
name: devkit-install-cleanup
description: Install, configure, validate, uninstall, and clean up dev.kit on the host (includes Codex integration checks).
---

# dev.kit Install & Cleanup

Use this skill when you need to install dev.kit, perform initial configuration, validate the setup, or uninstall and clean up a host environment.

## Preflight

- Confirm repo root and current branch.
- Discover available dev.kit commands at runtime (e.g., `dev.kit --list` or `dev.kit --help`).
- Capture current state using the discovered diagnostics commands.

## Install

- Prefer the built-in install command discovered at runtime.
- If no install command exists, fall back to the repo install script.

## Enable shell integration

- Use the discovered enable command and pass the current shell.
- If you need to revert later, remove the `source ".../dev.kit.sh"` line from the shell profile.

## Validate

- Run the discovered diagnostics command.
- Run the discovered dev-mode test suite (if present).
- If Codex rules were changed, use the discovered rules commands and validate with `codex execpolicy check ~/.codex/rules/default.rules`.

## Uninstall

- Use the discovered uninstall command.
- If a purge option exists, use it only with explicit confirmation.

## Cleanup checklist

- Remove shell profile `source` line if still present.
- Verify binaries are removed:
- Use `command -v dev.kit` to verify the binary.
- Verify engine dir state:
- Check the engine directory `~/.udx/dev.kit`.

## Experience log

- Record results in `src/context/20_config/experience/` using the session summary template.
- If the repo provides a UX test harness, use it instead of retyping commands.
