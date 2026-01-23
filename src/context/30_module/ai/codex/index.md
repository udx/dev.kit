# Codex module context layer

This layer defines the Codex module metadata and dispatch behavior for dev.kit.

<details>
<summary>Prompt(Codex module schema builder)</summary>

You are a deterministic converter that transforms the Codex module context layer into a single JSON artifact.

Tenet: the Markdown is the configuration and source of truth. This prompt is only the script. Do not embed or assume any Codex-specific content beyond the generic conversion rules below.

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

- Prompt: see `Prompt(Codex module schema builder)` in this file.
- Destination: `public/modules/codex.json`.

## Sources

- Module overview: `./overview.md`.
- Workflows: `./workflows.md`.
- Skills: `./skills.md`.
- MCP servers: `./mcp.md`.
- Shared config references: `../../../20_config/` and `../../../20_config/ai/`.
