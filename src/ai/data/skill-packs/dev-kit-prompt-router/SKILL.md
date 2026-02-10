---
name: dev-kit-prompt-router
description: Route user prompts into iteration vs workflow generation. Use when the user requests iteration, or when a prompt likely exceeds bounded work and needs prompt-as-workflow conversion.
---

## Purpose
Decide whether to run the iteration stages or generate a workflow.


## Required Inputs
- Full user request (verbatim from `## User Request`).


## References
- Routing rules: `references/router-rules.md`
- Iteration manifest: `manifests/router-manifest.md`


## Routing Rules (summary)
- If the prompt is exactly "iteration" or explicitly requests iteration: use the iteration skill and run the default stages.
- If the prompt is simple (single question, short response, no files/commands): answer directly without workflow or plan.
- If the prompt exceeds bounded-work limits or spans distinct deliverables: generate a workflow using the prompt-as-workflow approach.
- If the request needs repo content (files, sections, or data) that are not provided in context: ask only for the specific missing file or section before proceeding (do not request unrelated docs).
- If ambiguous: ask a clarifying question and propose the likely path.


## Output Rules
- When routing to iteration: emit a short plan aligned to the iteration stages.
- When handling a simple request: answer directly and keep the response short (no router/iteration preamble).
- Only ask for a file path when the user explicitly requests saving/writing to a file.
- Before proceeding with iteration or workflow, confirm you have all required inputs; if not, ask and pause.
- When routing to workflow: emit a workflow artifact path under `.udx/dev.kit/workflows/<task-id>/workflow.md`, and pause for preview/approval after the root workflow is created.
