# CDE context system

The CDE context system is the handler and dispatcher for structured context in dev.kit. It uses integrated metadata, supports unlimited nested levels, and treats CDE-compliant context documents as configuration sources for different output types.

<details>
<summary>Prompt(Context schema builder)</summary>

You are a deterministic converter that transforms a single CDE context Markdown document into a single JSON artifact.

Tenet: the Markdown is the configuration and source of truth. This prompt is only the script. Do not embed or assume any CDE-specific content beyond the generic conversion rules below.

Output requirements
- Output JSON only. No markdown fences, no commentary.
- Deterministic: same input -> same JSON output.
- Do not invent content. If something is absent in Markdown, omit it in JSON (unless required by the schema you infer from the Markdown itself).
- Preserve literals exactly (code blocks, inline code, tokens like $vars). Never execute or expand variables.
- Prefer stable identifiers and round-trip safety.

Parsing and normalization rules

1) Document framing
- H1 becomes: title
- The first paragraph after H1 (if any) becomes: summary

2) Headings -> structure
- H2 headings create top-level JSON sections.
- H3+ headings create nested objects inside their nearest parent section.
- Heading keys must be normalized to lowerCamelCase.
- Preserve original heading text in an optional field: _heading (string) when useful for round-trip fidelity.

3) Lists
- Numbered lists become arrays preserving order.
- Bullet lists become arrays.
- Definition-style bullets are detected and normalized:
  - Pattern A: "**term**: description" -> object { id, description }
  - Pattern B: "term: description" (when term is short and description is longer) -> object { id, description }
- Normalize ids:
  - If the id contains "/" keep it as-is.
  - Otherwise lower-case; convert spaces to "-" (kebab-case); strip surrounding punctuation.

4) Tables
- Markdown tables become arrays of row objects.
- Header cells become object keys (normalized to lowerCamelCase).
- Keep dashes and placeholders as literal strings (do not coerce to null).

5) Code blocks and literals
- Any fenced code block becomes an object:
  { "type": "code", "lang": "<lang or empty>", "value": "<exact contents>" }
- Attach code objects to the closest relevant section based on proximity:
  - If inside a heading section, store under that section.
  - If unclear, store in a top-level array: literals[].

6) Inline code
- Preserve inline code verbatim in the surrounding string content.
- Do not interpret inline code as structure unless it matches a definition/list rule.

7) Round-trip fidelity
- Preserve order where meaningful:
  - For each object created from headings, optionally include _order: [<child keys in appearance order>].
  - For arrays derived from lists, preserve list order.
- If you encounter content that does not fit any rule, store it under:
  extensions: { notes: [ ... ] }
  Do not drop information.

8) Root metadata
- If the Markdown provides explicit spec/version metadata, include it.
- If not provided, omit spec/version fields (do not guess).

9) Final output
- Emit one JSON object as the sole output.
- Ensure the JSON is valid, UTF-8, and uses consistent key naming (lowerCamelCase for keys; ids as described above).

</details>

## Transformation

- Prompt: see `Prompt(Context schema builder)` in this file.
- Destination: `src/schema/context.json`.

## Context dispatcher

- `src/context` is the context handler and dispatcher for dev.kit.
- Context documents are configuration inputs for different output types.
- Context layers can be nested without a depth limit.
- Integrated metadata is required to support deterministic parsing and merging.

## Development context layers

- Software-specific standard (build).
- 12-factor GitHub repo standard (deployment).
- Context Driven Engineering standard (active context layer).

## Dynamic schema

- `index.md` defines global config schema rules (applies to all nested levels).
- Child `index.md` extends parent rules; overrides are allowed only if parent explicitly permits.

## Merge order
- Parent rules apply first, then child rules.
- If overrides are permitted, child values replace parent values for the same key.
- If overrides are not permitted, child can only add new keys.

## Dynamic variables
- `$child` resolves to all child dirs in the current directory. Alias for `$child.dirs`.
- `$child.files` resolves to all child files in the current directory.
- `$child[context]` resolves to all child files in `context/`. If absent or empty, returns `[]`.
- Non-wrapped variables are executable.
- Non-executable text: wrap in code fences to keep literal.

## Naming
- Use lowercase kebab-case for directory and file names.
- Use `index.md` as the entry point for each directory.

## Dynamic structure
- `src/`: CDE definition and global standards for dev.kit.
- `src/context/`: context dispatcher and layered context documents.
- `artifacts/`: build and execution outputs.

## Navigation

- Each directory should contain an `index.md` that documents its direct children.
- If missing, default behavior applies but may be inaccurate due to metadata absence.
- Do not list deep files here; rely on child indexes for discovery.

## Artifacts
- Artifacts are derived with `dev.kit build [--context=configs/modules/ai/codex]` by related context definition.
- Artifacts can be markdown, json, yml, or other module-specific formats.

## Artifact build

- Source context lives under `src/context/`.
- Build outputs live under `public/` or `src/schema/`.
- Build steps must document inputs, outputs, and any client-specific overlays.

## Validation & Tests

- Keep docs human-readable first.
- Machine parsing should be simple, deterministic, and tolerate minor variations.
- AI context depends on prompt generation and may vary across clients.
- Explicit sections/headings are optional but recommended when they improve clarity.

## Context layers

### human/build
Human-initiated, interactive build execution.

- **custom**: Parameterized, operator-defined execution path.
- **real-time**: Observable execution with live feedback and step visibility.
- **multi-step**: Guided execution flow with state, checkpoints, and progressive disclosure (wizard-style, context-aware).

### programmatic/deploy
Machine-initiated, deterministic deployment execution.

- **inputs**: Explicit input contract (flags, payloads, schema-validated parameters).
- **default**: Opinionated execution using standard inputs and conventions.
- **single/scroll**: Single, linear execution record optimized for inspection and automation.

### ai/context
Context-aware, adaptive execution and orchestration.

- **interpret**: Derives intent from partial, ambiguous, or conversational input.
- **compose**: Assembles workflows dynamically from standards and active context.
- **mediate**: Bridges human intent and programmatic execution safely and predictably.
- **optimize**: Adjusts steps, ordering, or defaults based on historical and situational context.

## Standards stack

1. Software Source Standard (Build)
- Defines how source artifacts are discovered, built, tested, and packaged.
- Language and runtime conventions.
- Build steps and artifacts.
- Test and scan expectations.

2. 12-Factor GitHub Repo Standard (Deployment)
- Defines how repositories behave as deployable units.
- Declarative configuration.
- Environment separation.
- Immutable artifacts.
- Explicit backing services.

3. Context Driven Engineering Standard (Active Context Layer)
- Defines how context influences execution across all layers.
- Who is acting (human, system, AI).
- Why the action is occurring (intent).
- Where it runs (environment, trust boundary).
- What constraints apply (policy, security, compliance).
- What is already known (history, state, artifacts).
- This layer is always active and never bypassed.

## Vocabulary

Vocabulary is layer-agnostic and maps consistently across experiences.

### Experience
- **interactive**: Human-friendly, conversational or wizard-based flow (CLI step-by-step, UI, AI-guided).
- **programmatic**: Machine-friendly, explicit and deterministic (CLI flags, API payloads, CI pipelines).
- **integrated**: Declarative, configuration-driven (config files, repo manifests, policy definitions).

### Vocabulary - Layer Mapping (Conceptual)

| vocabulary | human/build | programmatic/deploy | ai/context |
|---|---|---|---|
| interactive | Wizard, live logs | - | Conversational intent |
| programmatic | Optional overrides | Primary interface | Execution target |
| integrated | Presets, profiles | Defaults, contracts | Context memory |

## Key design principle

The same action must be expressible as:
- a conversation (AI),
- a guided flow (human),
- or a contract (programmatic),
without changing its meaning.

AI does not introduce a new execution model.
It operates as a context compiler that selects the appropriate layer and experience.
