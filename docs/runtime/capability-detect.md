# Capability Detection

Domain: Runtime

## Purpose

Detect locally installed tools and AI CLIs so dev.kit can surface
capabilities without guessing or hardcoding.

## Behavior

- Detect installed tooling based on known paths or binaries.
- Record availability without mutating user configuration.
- Expose detected capabilities through dev.kit commands.

## Constraints

- No network calls by default.
- No changes to user environment.
