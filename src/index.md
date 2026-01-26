# CDE definition

Context Driven Engineering (CDE) is a repository standard that keeps artifacts consistent across human, programmatic, and AI contexts. This document defines CDE for dev.kit.

<details>
<summary>Prompt(CDE schema builder)</summary>

You are a deterministic converter that transforms a single CDE Markdown document into a single JSON artifact.

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

- Prompt: see `Prompt(CDE schema builder)` in this file.
- Destination: `public/schema/index.json`.

## Purpose

- Define the CDE standard for dev.kit.
- Provide a shared vocabulary and model across human, programmatic, and AI contexts.
- Keep CDE principles stable even as modules evolve.

## Standards stack

1. **Software source standard (build)**
   Defines how source artifacts are discovered, built, tested, scanned, signed, and packaged.

2. **12-factor GitHub repo standard (deployment)**
   Defines how repositories behave as deployable units via conventions, declarative configuration, and environment separation.

3. **Context Driven Engineering (active context layer)**
   Defines how execution context influences behavior across all layers. This layer is always active and never bypassed.

## Development context layers

### human/build
Human-initiated, interactive build execution.

- **custom**: Parameterized, operator-defined execution path.
- **real-time**: Observable execution with live feedback and step visibility.
- **multi-step**: Guided execution flow with state, checkpoints, and progressive disclosure.

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

## Vocabulary

Vocabulary is layer-agnostic and maps consistently across experiences.

### Core terms
- **context layer**: A directory that contains an `index.md`. Only such directories participate in CDE context resolution.
- **context asset**: A markdown document located within a context layer (typically `index.md` or any document under that layer's `context/` subtree).
- **context schema**: A JSON configuration that defines machine-validated structure for a context layer (e.g., `index.json`, `schema.json`, or an embedded JSON schema block).

### Experience
- **interactive**: Human-friendly guided or conversational flow (CLI wizard, UI, AI-guided).
- **programmatic**: Machine-friendly, explicit and deterministic (CLI flags, API payloads, CI pipelines).
- **integrated**: Declarative, configuration-driven (config files, repo manifests, policy definitions).

### AI essentials and human analogy

| AI essential | Human analogy (what it looks like) | Typical output artifact |
|------------|-------------------------------------|-------------------------|
| **interpret** | Clarify intent, restate requirements, ask the right steps | Intent summary |
| **compose** | Draft a runbook, choose an approach, sequence steps | Plan / workflow spec |
| **mediate** | Gatekeeping, approvals, policy checks, safety reviews | Decision record |
| **optimize** | Refactor, simplify, reuse patterns, avoid repetition | Improved plan / defaults |

| Human capability (build) | AI analog (what AI does) | Typical output artifact |
|--------------------------|--------------------------|-------------------------|
| **custom** | Parameter selection and constraint satisfaction | Parameter set |
| **real-time** | Live summarization + anomaly surfacing | Status narrative |
| **multi-step** | Stateful orchestration + checkpointing | Step trace |

| Programmatic capability (deploy) | AI analog (what AI does) | Typical output artifact |
|----------------------------------|---------------------------|-------------------------|
| **inputs** | Schema-driven extraction/validation | Validated payload |
| **default** | Default selection using context + policy | Resolved configuration |
| **single/scroll** | Post-run synthesis into one consumable trace | Run report |

## Repository structure

- `src/` Source manifests for humans, programs, and AI, including the CDE definition.
- `src/context/` Layered context and build rules; see `src/context/index.md` for the dispatcher model.
- `public/` Built artifacts intended to be copied or consumed directly.
- `public/schema/` JSON artifacts derived from Markdown sources.

## Artifacts and build

- Sources live under `src/` and `src/context/`.
- Outputs live under `public/`.
- Build steps must document inputs, outputs, and any client-specific overlays.

## Validation & tests

- Human readability is the primary goal.
- Machine parsing should be simple, deterministic, and tolerant of minor variations.
- AI context depends on prompt generation and may vary across clients.

## Design principle

The same action must be expressible as:
- a conversation (AI),
- a guided flow (human),
- a contract (programmatic),

without changing its meaning.

AI does not introduce a new execution model; it acts as a context compiler that selects the appropriate layer and experience.
