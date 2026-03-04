# YAML Standards for Teams

## Summary

YAML is common for configuration, but inconsistent structure hurts readability and automation. A shared standard reduces friction and prevents errors.

## When To Use

- Defining config formats for new modules.
- Aligning config style across repositories.
- Adding schema validation to CI.

## Quick Answers

- "Should we use YAML?" -> use only if human editing is required.
- "How do we avoid drift?" -> enforce schema validation and linting.
- "How do we keep files manageable?" -> keep single-purpose files and explicit defaults.

## Suggested Practices

- Enforce linting and schema validation.
- Define required keys and allowed values.
- Prefer explicit defaults over implicit behavior.
- Document environment-specific overrides.
- Keep files small and focused.

## dev.kit Notes

- Prefer JSON for machine-only configs.
- Keep templates separate from rendered outputs.

## Source

- https://andypotanin.com/creating-yaml-standards-best-practices-for-teams/
