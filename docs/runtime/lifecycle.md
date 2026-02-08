# Runtime Lifecycle

Domain: Runtime

## Purpose

Define the lifecycle phases that support local usage.

## Interfaces

- bin/scripts/install.sh
- bin/env/dev-kit.sh (shell init)
- bin/scripts/uninstall.sh

## Behavior

- Install into a user-controlled location.
- Shell integration is opt-in and confirmed.
- Completions are installed when supported.
- Uninstall removes local state only when requested.

## First-Run Expectations

- Provide a minimal status summary.
- Offer next steps without forcing integrations.
