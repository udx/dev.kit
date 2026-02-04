---
name: prompt-router
description: Route user prompts into iteration vs workflow generation. Use when the user requests iteration, or when a prompt likely exceeds bounded work and needs prompt-as-workflow conversion.
---

# Prompt Router

Purpose: Decide whether to run the iteration stages or generate a workflow.

## References

- Routing rules: `references/router-rules.md`
- Iteration manifest: `manifests/router-manifest.md`

## Routing Rules (summary)

- If the prompt is exactly "iteration" or explicitly requests iteration: use the iteration skill and run the default stages.
- If the prompt exceeds bounded-work limits or spans distinct deliverables: generate a workflow using the prompt-as-workflow approach.
- If ambiguous: ask a clarifying question and propose the likely path.

## Output Rules

- When routing to iteration: emit a short plan aligned to the iteration stages.
- When routing to workflow: emit a workflow artifact path under `.udx/dev.kit/workflows/<task-id>/workflow.md`, and pause for preview/approval after the root workflow is created.
