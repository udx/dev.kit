---
name: dev-kit-mermaid-export
description: Convert Mermaid (.mmd) diagrams into high-quality SVG files for documentation and web assets. Use this skill when the 'dev-kit-diagram-generator' is not sufficient or when batch processing existing files.
---

## Objective
Convert local Mermaid files into SVG assets, ensuring consistent styling and rendering for documentation.

## CLI Usage Example
```bash
# Export a specific Mermaid file to SVG
dev.kit skills run "Export docs/diagrams/arch.mmd to SVG"

# Export multiple Mermaid files
dev.kit skills run "Convert all .mmd files in assets/ to SVG"

# Batch export to a specific directory
dev.kit skills run "Export all diagrams to artifacts/output/"
```

## Required Inputs
- `source`: One or more `.mmd` file paths or a directory containing them.

## Optional Inputs
- `output_dir`: Target directory for SVG files (default: same as source).

## Logic
1. Identify `.mmd` files from the provided `source`.
2. Execute the Mermaid CLI (`mmdc`) or project-specific export scripts.
3. Validate SVG output and report the location of generated assets.

## Output Rules
- Provide a summary of all converted files and their final paths.
