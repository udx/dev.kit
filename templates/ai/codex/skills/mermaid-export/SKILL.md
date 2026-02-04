---
name: mermaid-export
description: Convert Mermaid .mmd diagrams to .svg files, especially for article assets.
---

# Mermaid Export

Use this skill when the user asks to convert Mermaid `.mmd` files to `.svg` or to create/update Mermaid assets for articles.

## Quick start

- Single file:
  - `mmdc -i <input.mmd> -o <output.svg>`
- Directory (all .mmd files):
  - `scripts/convert-all.sh <input-dir> <output-dir>`

## Workflow

1) Locate `.mmd` files (often under `src/articles/<article>/`).
2) Convert to `.svg` with `mmdc`.
3) Keep filenames stable and place SVGs next to the `.mmd` files unless the user requests a separate output directory.

## Style guidance

- Match repo examples in `README.md` (Mermaid flowchart style).
- Prefer `flowchart TD` and `<br/>` line breaks for multi-line labels.
- Keep labels short and concrete; avoid styling directives unless already used in repo examples.

## Notes

- `mmdc` comes from `@mermaid-js/mermaid-cli`.
- If the CLI is missing, ask before installing and prefer the user's package manager.
