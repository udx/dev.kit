# Context Adaptation

## Summary

Adaptation projects shared sources into tool-specific formats. It is optional and should be reversible.

## What It Does

- Applies projections and filters.
- Maps shared sources to tool-specific formats.
- Keeps canonical intent unchanged.

## Boundaries

- Must not reinterpret intent.
- Must not invent interfaces or schemas.
- Must not bypass CLI constraints.
- Must not execute or persist state.

## Practical Rule

- Keep tool-specific formats out of canonical sources.
