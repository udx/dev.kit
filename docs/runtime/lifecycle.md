# Runtime Lifecycle

Domain: Runtime

## Purpose

Define the lifecycle phases that support local usage.

## Interfaces

- dev.kit install
- dev.kit enable
- dev.kit uninstall

## Behavior

- Install into a user-controlled location.
- Shell integration is opt-in and confirmed.
- Completions are installed when supported.
- Uninstall removes local state only when requested.

## First-Run Expectations

- Provide a minimal status summary.
- Offer next steps without forcing integrations.
