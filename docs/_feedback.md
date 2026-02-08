# Workflow: Create DOC-001 — CLI Primitives Vocabulary
domain: execution
type: workflow
id: review-002-doc-001
version: 0.1
status: draft
repo_scope: docs
source: review-002 (spec-kernel)
done: true

## Purpose
Create the foundational spec:
`docs/execution/cli-primitives.md`

This document defines the **stable, versioned execution vocabulary** for dev.kit.
All workflows, adapters, and reasoning systems MUST reference this vocabulary.
No execution semantics may exist outside it.

This is the first document in the spec kernel and unblocks all subsequent specs.

---

## Constraints
- Tool- and model-neutral (no planner, no AI, no adapter names).
- Spec-first: define contracts, not implementation.
- Minimal but enforceable.
- Explicit guarantees and forbidden behaviors.
- Versioned from day one.
- No examples that imply implementation details.

---

## Step 1 — Analyze existing execution surfaces
done: true

Task:
Identify all implicit execution actions currently described across docs.

Input:
- docs/execution/index.md
- docs/runtime/index.md
- docs/cde/iteration.md

Logic/Tooling:
- repo.read(paths=[...])
- Extract verbs/actions that imply execution, mutation, validation, reading, writing, reporting.
- Group actions by intent (read, write, validate, execute, report).

Expected output/result:
- A short categorized list of execution intents that need primitives.
- No primitives defined yet.

---

## Step 2 — Define primitive categories
done: true

Task:
Define the minimal set of primitive categories required to support all execution intents.

Input:
- Categorized execution intents from Step 1.

Logic/Tooling:
- Normalize categories (e.g., repo, artifact, workflow, validation, report).
- Ensure categories are orthogonal and non-overlapping.
- Ensure categories can support iteration boundaries.

Expected output/result:
- A list of primitive categories with 1–2 sentence purpose each.

---

## Step 3 — Define individual CLI primitives
done: true

Task:
Define the individual CLI primitives under each category.

Input:
- Primitive categories from Step 2.

Logic/Tooling:
- For each primitive, define:
  - name
  - purpose
  - required inputs (fields only, no syntax)
  - normalized outputs
  - guarantees (determinism, repo-scope, auditability)
  - failure modes
- Keep vocabulary minimal; prefer fewer primitives with clear semantics.

Expected output/result:
- A complete list of primitives with structured definitions.
- No reference to implementation details.

---

## Step 4 — Define stability and compatibility rules
done: true

Task:
Define versioning, stability guarantees, and breaking-change rules for CLI primitives.

Input:
- Primitive definitions from Step 3.
- Interface stability rules from cde/contracts.md.

Logic/Tooling:
- Add a “Stability & Versioning” section:
  - semantic meaning of versions
  - what constitutes a breaking change
  - backward compatibility expectations
- Explicitly link this doc as a stable interface per CDE contracts.

Expected output/result:
- Clear, enforceable stability rules for CLI primitives.

---

## Step 5 — Define forbidden behaviors
done: true

Task:
Explicitly define what CLI primitives MUST NOT do.

Input:
- Existing constraints from CDE and execution docs.

Logic/Tooling:
- Enumerate forbidden behaviors, including at minimum:
  - executing without validation
  - mutating intent
  - bypassing iteration boundaries
  - invoking adapters or planners directly
  - performing hidden side effects

Expected output/result:
- A “Forbidden Behaviors” section that closes common escape hatches.

---

## Step 6 — Write the canonical document
done: true

Task:
Create `docs/execution/cli-primitives.md` as a complete spec.

Input:
- Outputs from Steps 1–5.

Logic/Tooling:
- artifact.write(create):
  - path: docs/execution/cli-primitives.md
  - content:
    - header (name, version, domain)
    - purpose
    - primitive categories
    - primitive definitions
    - stability & versioning
    - forbidden behaviors
    - references to CDE contracts

Expected output/result:
- New file created: `docs/execution/cli-primitives.md`
- Document is self-contained and enforceable.

---

## Step 7 — Validate against contracts
done: true

Task:
Validate the new doc against existing contracts.

Input:
- docs/execution/cli-primitives.md
- docs/cde/contracts.md

Logic/Tooling:
- Manual checklist:
  - Is this doc referenced as a stable interface?
  - Are guarantees explicit?
  - Are forbidden behaviors listed?
  - Is it tool-neutral?
- repo.search for tool-specific terms (should be none).

Expected output/result:
- Pass/fail validation checklist.
- List of any violations if found.

---

## Step 8 — Update feedback artifact
done: false

Task:
Update `docs/_feedback.md` to record creation of DOC-001.

Input:
- Validation result from Step 7.

Logic/Tooling:
- artifact.write(update):
  - Mark DOC-001 as created/resolved.
  - Append resolution entry with:
    - doc id
    - file path
    - summary

Expected output/result:
- `docs/_feedback.md` updated with resolution log entry.

---

## Completion Criteria
This workflow is complete when:
- All steps are marked done: true
- `docs/execution/cli-primitives.md` exists
- The document is referenced as a stable interface in CDE contracts
- No tool-specific or adapter-specific language exists
- Feedback artifact reflects completion of DOC-001

## Status

- DOC-001: resolved

## Resolution Log

- DOC-001: created `docs/execution/cli-primitives.md` and marked as stable interface.
- REVIEW-2026-02-04: fixed prompt template inheritance parsing and removed stray files (`src/prompts/ai/index.md`, `src/prompts/ai/codex/index.md`, `_prompt.md`, `tmp.prompt`, `.DS_Store`, `src/_research/workflows/infra-configs-production-release.md`).
