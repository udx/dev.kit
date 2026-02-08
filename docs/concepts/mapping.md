# Source-to-Artifact Mapping

## Summary

Mapping is the step where source docs are normalized into tool-specific artifacts. It keeps sources stable while allowing multiple destinations.

## What It Does

- Keeps sources tool-agnostic.
- Produces disposable artifacts per tool.
- Enables validation without changing the source.

## Flow

1. Author or update a source.
2. Choose destination(s).
3. Run a sync step.
4. Validate in the target tool.

## Validation Checklist

- Format matches tool specification.
- Artifact reflects latest source.
- Tool loads it without errors.
