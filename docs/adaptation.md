# Context Adaptation

Domain: Context Adaptation

## Purpose

Define how context is projected and consumed by reasoning systems without
creating a separate AI layer.

## Scope

- Context is adapted via projections, filters, and tool-specific formats.
- Interfaces are model-agnostic; contracts are stable.

## Behavior

- Adaptation is optional and explicitly enabled.
- Rules, skills, and profiles are minimal and transparent.
- Tool-specific formats are mapped from shared sources.

## Forbidden Behaviors

Adaptation MUST NOT:
- Modify or reinterpret intent.
- Invent interfaces or schemas.
- Bypass CLI constraints.
- Execute or persist state.

## Constraints

- No tool-specific formats in canonical sources.
- Adaptation must be reversible and auditable.
