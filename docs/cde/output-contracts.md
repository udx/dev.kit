# CDE Output Contracts (DOC-002)

Domain: CDE

## Purpose

Define output requirements for deterministic iteration and workflow artifacts.

## Output Types

Outputs must declare a single `output_type`:
- `prompt`: machine-consumable, execution-ready.
- `markdown`: human-readable narrative or explanation.

Rules:
- Do not mix prompt and markdown in the same artifact.
- If a prompt needs explanation, create a separate markdown artifact.

## Bounded Work Policy

Every workflow artifact must encode the bounded limits:
- max_steps_per_iteration: 7
- max_files_per_step: 5
- max_new_files_per_iteration: 4
- max_move_operations_per_step: 10
- extract_child_workflow_if_any_exceeded: true

If any limit is exceeded, a child workflow must be created before continuing.

## Artifact Requirements

All iteration artifacts must include:
- `output_type`
- `bounded_work` limits
- explicit step boundaries
- clear inputs and expected outputs
