# Execution and Workflows

Domain: Execution

## Purpose

Use dev.kit as the execution wrapper and reasoning systems for planning.

## Interfaces

- dev.kit exec (prompt normalization and execution wrapper)
- Planning mechanisms (planning only)

## Documents

- iteration-loop.md (review → workflow → apply → validate → log)
- cli-primitives.md (stable execution vocabulary)
- prompt-as-workflow.md (workflow framing)

## Behavior

- Reasoning systems propose steps; dev.kit runs them.
- Each step maps to a single command or explicit short sequence.
- Nested steps are allowed when a step is too complex.

## Boundary

- Execution defines decomposition and workflow semantics.
- Runtime defines lifecycle, hooks, and state capture.

## Normalization Rule

Freeform input MUST be normalized into contracts and artifacts before it
can influence execution.

## Constraints

- Avoid recursive invocation (planning mechanisms should not call dev.kit exec).
- Execution authority stays with dev.kit.
