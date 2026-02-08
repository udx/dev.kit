# Configuration

Domain: Configuration

## Purpose

Provide minimal, safe defaults that are easy to understand and reverse.

## Interfaces

- dev.kit config show
- dev.kit config set
- dev.kit config reset

## Defaults

- Minimal, explicit options.
- Integrations are opt-in.
- Each option is explained.

## State Path

- `state_path` controls the runtime state directory.
- Example: `dev.kit config set --key state_path --value "~/.udx/dev.kit/.state"`
