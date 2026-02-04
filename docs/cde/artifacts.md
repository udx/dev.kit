# CDE Artifacts

Domain: CDE

## Purpose

Define the artifact types that carry executable context.

## Artifact Types

- Command schemas
- Input/output manifests
- Validation rules
- Context resolvers
- Prompt artifacts (signature, body, adapters)

## Constraints

- Artifacts are machine-derivable or machine-readable.
- Artifacts are versioned and auditable.
- Prompt artifacts are explicit, versioned, and validated.

## Prompt Artifacts

- Signature: inputs, outputs, invariants (stable contract)
- Body: instructions/template (provider/model-specific)
- Adapters: rendering for each provider/model
