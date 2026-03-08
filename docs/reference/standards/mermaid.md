# Mermaid Standards: Visual Engineering

**Domain:** Reference / Standards  
**Status:** Canonical

## Summary

**Mermaid** is the primary standard for all engineering diagrams (Flowcharts, Sequence Diagrams, State Machines). In **dev.kit**, Mermaid ensures that architecture and process flows are version-controlled alongside source code and accessible to both humans and agents.

---

## 🛠 dev.kit Grounding: Visual-to-Action

| Diagram Practice | dev.kit Implementation | Primitive / Command |
| :--- | :--- | :--- |
| **Diagram Generation** | Automated rendering of SVG/PNG assets. | `dev.kit visualizer` |
| **Resilient Fallback** | Fallback to raw Markdown if rendering fails. | `workflow.md` |
| **Unified Logic** | Synchronized view of code and architecture. | `dev.kit status` |
| **Intent-to-Action** | Visual mapping of normalized workflows. | `docs/skills/` |

---

## 🏗 High-Fidelity Mandates

### 1. Versioned Architecture
Never store diagrams as binary blobs. All architectural context must live as Mermaid source code to ensure it remains discoverable and diffable.
- **Action**: Use the `dev.kit visualizer` to export high-fidelity assets from `.mmd` sources.

### 2. Standardized Shapes
Maintain visual consistency to ensure agents can accurately reason about process flows.
- **`[Rectangle]`**: Processes / Normalizations.
- **`{Rhombus}`**: Decision Gates / Skill Selection.
- **`([Rounded])`**: Start / End Points.

---

## Operational Cues

- **Outdated Diagram?** -> Run `dev.kit visualizer` to regenerate assets from repository truth.
- **Broken Flow?** -> Check the raw Mermaid source in the `assets/diagrams/` hub.

---
## 📚 Authoritative References

Visual engineering is a core part of maintaining high-fidelity documentation:

- **[Synthetic Content Enrichment](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: Strategies for maintaining standalone quality through visual standards.
- **[AOCA: Visual Standards](https://udx.io/cloud-automation-book/quality)**: High-fidelity patterns for architectural documentation.

---
_UDX DevSecOps Team_
