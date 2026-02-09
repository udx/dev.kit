# CLI Primitives Vocabulary

Domain: Execution
Version: 0.1
Stability: stable

## Purpose

Define the stable, versioned execution vocabulary used by workflows and
reasoning systems. All execution semantics must be expressed using these
primitives.

## Primitive Categories

- Read: access repository or artifact state without mutation.
- Write: persist artifacts or outputs with explicit constraints.
- Validate: verify inputs, artifacts, and outputs against contracts.
- Execute: perform bounded, validated operations through CLI boundaries.
- Report: emit normalized summaries for humans and systems.
- Capture: record inputs, outputs, and metadata for audit.

## Primitive Definitions

### read

Purpose:
- Retrieve repository or artifact state without side effects.

Required inputs:
- target
- scope
- constraints
- expected_format

Normalized outputs:
- data
- metadata
- status

Guarantees:
- Deterministic for identical inputs and state.
- Repo-scoped and bounded.

Failure modes:
- not_found
- permission_denied
- constraint_violation

---

### write

Purpose:
- Persist artifacts or outputs with explicit constraints.

Required inputs:
- target
- payload
- schema
- mode
- constraints

Normalized outputs:
- artifact_id
- checksum
- status

Guarantees:
- Writes are validated against the provided schema.
- No implicit mutation outside the target scope.

Failure modes:
- validation_failed
- permission_denied
- constraint_violation

---

### validate

Purpose:
- Verify inputs, artifacts, and outputs against contracts.

Required inputs:
- target
- schema
- ruleset

Normalized outputs:
- status
- errors
- warnings

Guarantees:
- Deterministic for identical inputs and rules.

Failure modes:
- validation_failed
- invalid_schema

---

### execute

Purpose:
- Perform bounded operations through validated CLI boundaries.

Required inputs:
- operation
- arguments
- constraints
- validation_refs

Normalized outputs:
- result
- status
- logs

Guarantees:
- Execution only occurs after validation.
- Repo-scoped and bounded by constraints.

Failure modes:
- validation_failed
- execution_failed
- constraint_violation

---

### report

Purpose:
- Emit normalized summaries for humans and systems.

Required inputs:
- source
- format
- scope

Normalized outputs:
- report
- status

Guarantees:
- Non-mutating and deterministic.

Failure modes:
- invalid_format

---

### capture

Purpose:
- Record inputs, outputs, and metadata for audit.

Required inputs:
- context
- inputs
- outputs
- metadata

Normalized outputs:
- capture_id
- status

Guarantees:
- Append-only; no mutation of prior records.

Failure modes:
- storage_error
- permission_denied

## Stability and Versioning

- Versions follow semantic meaning: major.minor.
- Backward compatibility is required within a major version.
- Breaking changes include:
  - removing or renaming required fields
  - changing field meaning or semantics
  - changing guarantees or failure modes

This document is a stable interface per CDE contracts.

## Forbidden Behaviors

CLI primitives MUST NOT:
- execute without validation
- mutate intent sources
- bypass iteration boundaries
- invoke planning mechanisms directly
- perform hidden side effects

## References

- CDE contracts define stability and compatibility rules.
- CDE iteration defines iteration boundaries.
