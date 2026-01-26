# CDE Contracts

Domain: CDE

## Purpose

Define the contract boundaries between intent, interface, and execution.

## Contract Rules

- Intent is declared in canonical sources.
- Interfaces are expressed as schemas and manifests.
- Execution only happens through validated CLI boundaries.

## Canonical Intent Sources

- docs/index.md (root vision and hierarchy)
- docs/*/index.md (domain constraints)
- docs/cde/contracts.md (contract rules)
- docs/cde/iteration.md (iteration contract)

## Contract Invariants

- Canonical intent sources are immutable within an iteration.
- Interfaces are versioned and backward-compatible within a major version.
- Execution MUST NOT reinterpret intent or interfaces.
- Any change that alters CLI input/output is a breaking contract change.

## Interface Stability Scope

Stable interfaces:
- execution/cli-primitives.md
- cde/output-contracts.md
- execution/workflow-io-schema.md

Informational (non-stable):
- explanatory docs
- examples
- tooling notes

Breaking changes include:
- removing or renaming required fields
- changing field meaning or semantics
- changing CLI primitive guarantees
- changing validation gate meaning
