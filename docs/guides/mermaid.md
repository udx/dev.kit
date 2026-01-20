Mermaid Diagrams (dev.kit)

Goal
- Generate lightweight diagrams from prompts.
- Keep diagrams consistent and easy to read.

Approach
- Use dev.kit to generate a prompt-to-mermaid template.
- Optionally use AI CLI for refinement and editing.

Example
```bash
dev.kit -p "generate mermaid diagram: dev.kit flow"
```

Notes
- Prefer `flowchart TB` for short, top-down diagrams.
- Keep node labels short and consistent.
