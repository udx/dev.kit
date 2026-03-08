---
name: dev-kit-visualizer
description: PRIMARY skill for visual engineering. Generate high-fidelity Mermaid diagrams and convert them into SVG exports. Use this for architecture, process flows, sequence diagrams, and ER diagrams.
---

## Objective
Enable seamless transition from "Intent" to "Visual Asset" by automating both the creation of Mermaid (.mmd) diagrams and their rendering into SVG documentation.

## CLI Usage Example
```bash
# Generate a new flowchart diagram
dev.kit visualizer create flowchart "assets/arch.mmd"

# Export an existing Mermaid file to SVG
dev.kit visualizer export "assets/arch.mmd"

# Or resolve intent directly (Dynamic Normalization)
dev.kit skills run "visualizer" "Create a sequence diagram for 'Auth Flow' and export it to SVG"
```

## Success-First UX Contract
- **Deterministic Templates**: Always start from UDX-standard Mermaid templates.
- **Resilient Rendering**: Use `mmdc` (Mermaid CLI) with consistent styling.
- **Auto-Discovery**: Automatically find and batch-process `.mmd` files when requested.

## Capabilities
- **Create**: Initialize flowchart, sequence, state, or ER diagrams from templates.
- **Render**: Convert `.mmd` to `.svg` (Batch or Single).
- **Batch**: Process all diagrams in a directory for documentation updates.

## Workflow (Full Loop)
1. Request a specific diagram type (e.g., Sequence).
2. `new_diagram.sh` generates the `.mmd` from `assets/templates/`.
3. Edit or refine the `.mmd` logic.
4. `export_svg.sh` renders the final `.svg` for documentation.

---
_UDX DevSecOps Team_
