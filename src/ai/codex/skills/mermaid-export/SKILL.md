---
name: mermaid-export
description: Convert Mermaid .mmd diagrams to .svg files, especially for article assets.
---

# Mermaid Export

Use this skill when the user asks to convert Mermaid `.mmd` files to `.svg` or to
create/update Mermaid assets for articles.

## Config

Inputs are derived from the repo and environment when not provided explicitly.

- `mermaid.input` (required: .mmd file or directory)
- `mermaid.output` (optional: output file or directory)
- `mermaid.cli` (default: `mmdc`)

## Logic

- Locate `.mmd` inputs.
- Convert to `.svg` using `mmdc`.
- Keep filenames stable and place SVGs next to inputs unless requested otherwise.
- Use `dev.kit` command wrappers where available (preferred over raw shell scripts).

## Schema

Inputs:
- `.mmd` file(s)

Outputs:
- `.svg` file(s) placed next to input or in the requested output directory

## Docs

Quick start:
- Single file: `mmdc -i <input.mmd> -o <output.svg>`
- Directory: prefer a dev.kit wrapper if present; otherwise run `mmdc` in a loop.
