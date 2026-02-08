# Context Driven Engineering (CDE)

## Summary

CDE describes how dev.kit turns repository intent into executable context. It is a practical model for artifacts, boundaries, and iteration.

## What CDE Is

- A way to express intent as concrete, versioned artifacts.
- A boundary model: intent in docs, execution through validated CLI.
- A contract that makes prompts and workflows predictable.

## Artifacts (Real Objects)

- Prompt templates: `src/ai/data/prompts.json`
- Skills and schemas: `src/ai/data/skills/`
- Workflow schema: `docs/cli/execution/workflow-io-schema.md`
- CLI primitives: `docs/cli/execution/cli-primitives.md`

## Contract Boundaries

- Intent lives in docs and specs.
- Interfaces are artifacts and schemas.
- Execution happens only through validated CLI boundaries.
- Determinism is enforced at those boundaries.

## Iteration Model

input
→ analyze
→ configure
→ execute
→ post-validate
→ report
→ notify

## Output Contracts

Outputs declare a single `output_type`:
- `prompt`: machine-consumable, execution-ready.
- `markdown`: human-readable narrative.

Workflow outputs also encode bounded limits:
- max_steps_per_iteration: 7
- max_files_per_step: 5
- max_new_files_per_iteration: 4
- max_move_operations_per_step: 10
- extract_child_workflow_if_any_exceeded: true

## References

- Prompt-as-workflow: `docs/cli/execution/prompt-as-workflow.md`
- Concepts: `docs/concepts/index.md`
