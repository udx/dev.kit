# Integration Configuration

Domain: Configuration

## Purpose

Define how integrations are enabled through contract-driven wiring.

## Behavior

- Integrations are opt-in.
- Global config stays minimal by default.
- Local overrides are temporary and explicit.
- AI integrations require `ai.enabled = true` to allow `dev.kit exec` to run external AI CLIs.

## Constraints

- Avoid hidden side effects.
- Integrations must be reversible.
- Configuration must not bypass CDE contracts.
