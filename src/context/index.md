# CDE context system

The CDE context system is the dispatcher for structured context in dev.kit. It defines how Markdown sources become normalized artifacts for humans, programs, and AI.

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
- Destination: `public/schema/context.json`.

## Role

- `src/context/` is the context dispatcher for dev.kit.
- Context documents are configuration inputs for different output types.
- Context layers can be nested without a depth limit.
- Integrated metadata enables deterministic parsing and merging.

## Context model

### Index inheritance
- `index.md` defines schema rules for the current directory scope.
- Only directories containing an `index.md` participate as context layers.
- A child directory `index.md` extends parent rules.
- Overrides are allowed only when the parent explicitly permits overrides for a given key.

### Merge order
1. Apply parent rules (base).
2. Apply child rules (extensions).
3. If overrides are permitted: child values replace parent values for the same keys.
4. If overrides are not permitted: child may only add new keys.

### Dynamic variables
- `$child` resolves to all child dirs in the current directory. Alias for `$child.dirs`.
- `$child.files` resolves to all child files in the current directory.
- `$child[context]` resolves to all child files in `context/`. If absent or empty, returns `[]`.
- Non-wrapped variables are executable.
- Non-executable text: wrap in code fences to keep literal.

### Naming
- Use lowercase kebab-case for directory and file names.
- Use `index.md` as the entry point for each directory.

## Source vs artifact

- Source context lives under `src/context/` (human- and AI-readable intent).
- Build outputs live under `public/`.
- Artifacts are ready to copy/use; they should not be treated as source.

## Navigation

- Each directory should contain an `index.md` that documents its direct children.
- Do not list deep files here; rely on child indexes for discovery.
- If `index.md` is missing, defaults apply but may be inaccurate due to absent metadata.

## Artifact build

- Build steps must document inputs, outputs, and any client-specific overlays.
- Context layers may define output formats (md/json/yml or module-specific).
- Execution tooling should remain deterministic and repo-driven.

## Validation & tests

- Keep docs human-readable first.
- Machine parsing should be simple, deterministic, and tolerate minor variations.
- AI context depends on prompt generation and may vary across clients.

## References

- CDE definition: `src/index.md`.
- Standards stack and vocabulary are defined there and referenced here.
