Role: deterministic repo architect for dev.kit.

Goal: convert the repo into a minimal, auditable "core engine" that implements CDE.
Priorities: cleanup, optimize docs, ensure CLI behavior, preserve auditability.

Audience: adapter
Output type: prompt (machine-consumable)

Hard constraints:
- Stable contracts stay tool-neutral.
- Core must exclude optional adapters; those become extensions.
- Prefer move/remove over duplication.
- Every move/update is recorded in an audit report.
- Split work into bounded iterations; extract a child workflow if bounds are exceeded.
- Move fast: default to "approve all" unless a step is explicitly marked as requiring manual intervention.
- Optimize for clarity: remove unuseful items, move useful items into the most related domain.
- Minimize root-level directories to make dev.kit components obvious.
  - useful: anything used as a programmatic or prompt source
  - unuseful: source that was converted into another optimized source or script/logic/manifest

Bounded Work Policy:
- max_steps_per_iteration: 7
- max_files_per_step: 5
- max_new_files_per_iteration: 4
- max_move_operations_per_step: 10
- extract_child_workflow_if_any_exceeded: true

Core engine must include:
- Runtime boundary: bin/, lib/, src/, config/
- Spec kernel in docs/:
  - CDE contracts (contracts, artifacts, iteration)
  - execution (cli primitives, workflow IO schema, iteration loop, extraction gate, prompt-as-workflow)
  - runtime (capability detect, lifecycle)
  - adaptation (rules: produces artifacts only)
- Iteration mechanism: skills/iteration.md, scripts/, prompts/, tasks/
- Minimal templates/assets/schemas needed by core
- CLI behavior:
  - `dev.kit` shows helper/usage output by default
  - `dev.kit detect` reports whether (codex|git|docker|npm) are enabled and whether related creds are available
- `dev.kit exec` performs normalized search or CLI execution (local or remote); if AI integration is enabled, run normalized Codex exec (prompt-as-workflow, iteration skill, etc.)

Workflow mechanism requirements:
- Input is prompt-as-workflow.
- Each step must be convertible into a workflow step (clear state, inputs, outputs).
- Track workflow step state (planned/in_progress/done/blocked).
- Require manual intervention for any critical input/approval to prevent repeat or unnecessary work.
- End with a clear report so the next prompt can resume from it.

Extensions:
- Optional AI adapters, MCP projections, non-core modules, examples/demos
- Move to extensions/ and not required by core

Target layout (propose/justify, minimal diffs):
bin/ lib/ src/ config/ docs/ skills/ scripts/ prompts/ tasks/ workflows/
schemas/ templates/ assets/ extensions/

Required specs:
- docs/cde/output-contracts.md (DOC-002) encodes prompt vs markdown and bounded work
- docs/execution/workflow-io-schema.md (DOC-003) encodes workflow IO schema

You MUST produce artifacts:
1) Update README.md and docs/index.md to reflect the new layout and entry points

Execution rules:
- Artifacts only; no runtime behavior changes and no command execution.
- If DOC-002 or DOC-003 is missing or outdated, treat as first-class steps before cleanup.

Now do the work:
- Inspect repo structure and existing docs/specs.
- Produce the artifacts above and keep diffs minimal and auditable.
- End with a short "Next iteration" list (max 5 bullets).
- After the prompt-as-workflow iteration, output only these supported `dev.kit` commands and how to test them:
  - `dev.kit` (helper/usage)
  - `dev.kit install` / `dev.kit update` / `dev.kit uninstall`
  - `dev.kit exec`
  - `dev.kit config`
  - `dev.kit codex` (configure config/skills/rules)
- Include this concrete `dev.kit exec` test case:
  - `dev.kit exec "review assets and docs dir and cleanup/optimize"`
