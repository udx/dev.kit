# Source-to-Artifact Mapping

Domain: Mapping

## Purpose

Define how canonical sources become tool-specific artifacts while keeping
formats correct and independently updatable.

## Definitions

- Source: Canonical, human-friendly intent document.
- Mapper: Manual or scripted normalization step.
- Artifact: Tool-specific output consumed by an AI or CLI.

## Principles

- Sources are tool-agnostic.
- Mapping is explicit per destination.
- Artifacts are disposable and regeneratable.
- Sync is deliberate and validated.

## Flow

1. Author or update a source.
2. Choose the destination(s).
3. Run a sync step.
4. Validate in the target tool.
