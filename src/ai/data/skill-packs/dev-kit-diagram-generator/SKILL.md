---
name: dev-kit-diagram-generator
description: Generate Mermaid diagrams and optional SVG exports from process descriptions or .txt/.md files. Use when requests ask to create, revise, or export architecture/process visuals (flowchart, sequence, state, or ER) as Mermaid or SVG. Prefer this skill when a CLI-like intake contract, deterministic output paths, and graceful export fallback are required.
---

## Objective
Generate deterministic Mermaid diagrams from user input, then optionally export SVG, with a success-first UX that never dead-ends on tooling failures.

## Success-First UX Contract
- Require only `source`.
- Default `output=chat` if omitted.
- Ask only for missing required input.
- Do not ask optional customization questions unless user requests customization.
- If file export fails, still return valid Mermaid plus a concise recovery hint.

## Input Contract (CLI-like)
Required:
- `source`: pasted text, or path to readable `.txt`/`.md`

Optional:
- `output`: `chat|mmd|svg|both` (default `chat`)
- `diagram_type`: `auto|flowchart|sequenceDiagram|stateDiagram-v2|erDiagram` (default `auto`)
- `direction`: `TD|LR` (default `TD`; apply to flowchart only)
- `detail_level`: `summary|standard|detailed` (default `standard`)
- `output_path`: explicit target file path

Normalization rules:
- `sequence` => `sequenceDiagram`
- `state` => `stateDiagram-v2`
- `er` => `erDiagram`
- `inline` => `chat`
- Ignore unknown keys and append their names to `deferred`.

Validation rules:
- Invalid field name/value: return invalid field, allowed values, and one corrected minimal example.
- Missing required `source`: ask only for `source` and stop generation.

## Intake Prompt
If `source` is missing, ask exactly:

```text
Missing required input: source.
Send:
source: <paste text or provide a .txt/.md path>

Defaults active:
- output: chat
- diagram_type: auto
- direction: TD
- detail_level: standard

Optional overrides:
output: chat|mmd|svg|both
diagram_type: auto|flowchart|sequenceDiagram|stateDiagram-v2|erDiagram
direction: TD|LR
detail_level: summary|standard|detailed
output_path: <custom path>
```

## Copy-Paste Input Template
Accept and parse this one-shot format:

```text
source: <paste process text OR /path/to/file.md>
output: chat|mmd|svg|both
diagram_type: auto|flowchart|sequenceDiagram|stateDiagram-v2|erDiagram
direction: TD|LR
detail_level: summary|standard|detailed
output_path: <optional path ending in .mmd or .svg>
```

## Source Resolution
- Treat `source` as a file path only when it points to a readable `.txt` or `.md` file.
- Otherwise treat `source` as literal text.
- If source appears to be a path but cannot be read, return path + reason and request corrected path or pasted text.

## Output Path Policy
When file output is requested and `output_path` is absent:
- Base directory: `artifacts/diagrams/`
- Defaults:
  - `mmd`: `artifacts/diagrams/diagram.mmd`
  - `svg`: `artifacts/diagrams/diagram.svg`
  - `both`: both files above

Collision handling:
- Never overwrite existing output.
- Append `-N` numeric suffix (`diagram-1.mmd`, `diagram-2.mmd`, ...).
- For `both`, keep `.mmd` and `.svg` stems aligned.

## Resource Loading
- Prefer local templates in `assets/templates/`.
- Load `references/mermaid-patterns.md` only when type selection or syntax is unclear.
- Reuse repo-local `src/mermaid/*.mmd` only when files are non-empty and not placeholder content.

## Deterministic Helpers
- Use `scripts/new_diagram.sh <diagram_type> <output.mmd>` to scaffold a template-backed Mermaid file.
- Use `scripts/export_svg.sh <input.mmd> <output.svg>` for SVG export checks, non-clobber output behavior, and actionable errors.

## Workflow
1. Parse intake and normalize aliases.
2. Apply defaults and validate required/allowed values.
3. Resolve source from file or text.
4. Infer diagram type when `diagram_type=auto`.
5. Scaffold with closest template and build Mermaid content.
6. Validate syntax quickly:
- Header/type matches selected type.
- Edge references are defined.
- Node IDs are unique.
7. Emit per output mode:
- `chat`: return Mermaid as a fenced ```mermaid code block using real line breaks.
- `mmd`: write Mermaid file and return `mmd_path`.
- `svg`: generate temp `.mmd`, export `.svg`, return `svg_path`.
- `both`: write `.mmd`, export `.svg`, return both.
8. On SVG export failure, return Mermaid + concise remediation hint.

## Graceful Failure Ladder
1. Try `scripts/export_svg.sh`.
2. Fallback to `mmdc -i <input.mmd> -o <output.svg>`.
3. If SVG still fails, do not hard-fail: return Mermaid and explain next command to recover.

## Error Handling
- Unsupported `diagram_type`: return allowed values and request one.
- Unreadable `source` path: echo path + system reason.
- Oversized scope: propose phased split and proceed with phase 1.
- Restricted Chromium runtime: return Mermaid + no-sandbox Puppeteer hint.

## Output Contract
For `output=chat`, return exactly:

```mermaid
<diagram with real newlines>
```

Do not JSON-escape Mermaid (`\n`, `"`) in chat output.

Bad (do not emit): `{"mermaid":"flowchart TD\nA-->B"}`
Good (emit): a fenced Mermaid block with actual line breaks.

For file outputs (`mmd|svg|both`), return metadata JSON:

```json
{
  "diagram_type": "flowchart|sequenceDiagram|stateDiagram-v2|erDiagram",
  "template": "string",
  "mmd_path": "string (optional)",
  "svg_path": "string (optional)",
  "deferred": ["string"]
}
```

Optional: include a second fenced Mermaid block for preview, but keep metadata and Mermaid separate.

Partial-success rule:
- If `svg`/`both` requested and export fails, omit `svg_path`, keep Mermaid output, and add the recovery reason to `deferred`.

## Quality Bar
- Keep diagram readable at first glance (target <= 14 nodes unless user asks for detail).
- Keep ordering deterministic (top-down or left-right consistently).
- Prefer verb-first edge labels (`validates`, `publishes`, `retries`).
- Reflect only user-provided facts; mark assumptions explicitly.

## Source Design for Easy Maintenance
- Keep policy and UX contract in `SKILL.md` only.
- Keep syntax examples in `references/mermaid-patterns.md` only.
- Keep reusable skeletons in `assets/templates/` only.
- Keep deterministic file/export behavior in `scripts/` only.
- When updating behavior, change contract and script in the same commit.
