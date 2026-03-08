# Mermaid Syntax Standard

Domain: Standards

## Summary

`dev.kit` uses **Mermaid** for all engineering diagrams (flowcharts, sequence diagrams, state machines, etc.). Standardizing on Mermaid ensures that diagrams are version-controlled alongside source code and can be rendered by both human tools (GitHub/VSCode) and AI agents.

## External Documentation

- **Official Introduction**: [Mermaid Introduction](https://mermaid.js.org/intro/)
- **Syntax Reference**: [Mermaid Syntax Reference](https://mermaid.js.org/intro/syntax-reference.html)
- **Live Editor**: [Mermaid Live Editor](https://mermaid.live/)

## Repository Standards

1.  **Format**: Always use `flowchart LR` or `flowchart TD` for process flows.
2.  **Labels**: Keep labels short and action-oriented. Use `<br/>` for line breaks within nodes.
3.  **Consistency**: Use standard shapes for common actions:
    - `[Rectangle]` for Processes/Normalizations.
    - `{Rhombus}` for Decision Gates/Skill selection.
    - `([Rounded])` for Start/End points.
4.  **Resilience Fallback**: When a specialized diagram generator fails, `dev.kit` falls back to raw Mermaid markdown to ensure continuity.

---
_UDX DevSecOps Team_
