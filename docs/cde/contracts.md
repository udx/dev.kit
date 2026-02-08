# CDE Contracts

Domain: CDE

## Purpose

Define the contract boundaries between intent, interface, and execution.

## Contract Rules

- Intent is declared in canonical sources.
- Interfaces are expressed as schemas, manifests, and prompt artifacts.
- Execution only happens through validated CLI boundaries.
- Determinism lives at execution boundaries and artifact interfaces.

## Canonical Intent Sources

- docs/index.md (root vision and hierarchy)
- docs/*/index.md (domain constraints)
- docs/cde/contracts.md (contract rules)
- docs/cde/iteration.md (iteration contract)

## Canonical Intent Substrate

- Markdown is the canonical source of truth for repo intent.
- Headings, sections, and lists may be treated as a deterministic, compiler-friendly subset.
- JSON/YAML schemas and manifests are optional derived projections when strict tooling requires them.

## Contract Invariants

- Canonical intent sources are immutable within an iteration.
- Interfaces are versioned and backward-compatible within a major version.
- Execution MUST NOT reinterpret intent or interfaces.
- Any change that alters CLI input/output is a breaking contract change.
- Any change that alters prompt signature or validation guarantees is a breaking contract change.

## Interface Stability Scope

Stable interfaces:
- execution/cli-primitives.md
- cde/output-contracts.md
- execution/workflow-io-schema.md
- prompt artifacts

Informational (non-stable):
- explanatory docs
- examples
- tooling notes

Breaking changes include:
- removing or renaming required fields
- changing field meaning or semantics
- changing CLI primitive guarantees
- changing validation gate meaning
- changing prompt signature inputs/outputs or invariants
