# Skill: dev-kit-visualizer

**Domain:** Visual Engineering  
**Type:** AI Reasoning Skill  
**status:** Canonical

## Summary

The **Visual Engineering** skill empowers AI agents to transform repository context into high-fidelity diagrams. It uses dynamic reasoning to understand source code, flow, and architecture, then leverages the deterministic `dev.kit visualizer` command to render SVG assets.

---

## 🛠 AI Reasoning (The Skill)

This skill utilizes dynamic LLM reasoning to perform the following:
- **Flow Extraction**: Reading READMEs or source code to identify discrete process steps.
- **Visual Mapping**: Determining which Mermaid pattern (flowchart, sequence, state) best represents the intent.
- **Intent-to-MMD**: Generating raw Mermaid source code based on extracted logic.

---

## ⚙️ Deterministic Logic (Function Assets)

The following assets provide the programmatic engine for this skill:
- **Templates**: Standardized Mermaid patterns in `assets/templates/`.
- **Patterns**: High-fidelity Mermaid styling and shape standards.
- **Export Engine**: Hardened `mmdc` wrapper for SVG/PNG generation.

---

## 🚀 Primitives Orchestrated

This skill is grounded in the following **Deterministic Primitives**:
- **`dev.kit visualizer create`**: Initializes a new Mermaid source from templates.
- **`dev.kit visualizer export`**: Renders Mermaid sources into SVG/PNG.

---

## 📂 Managed Assets

- **Templates**: Standard flowchart, sequence, and state machine patterns in `docs/workflows/assets/templates/`.
- **Patterns**: High-fidelity Mermaid styling and shape standards in `docs/workflows/mermaid-patterns.md`.

---

## 📚 Authoritative References

Visual engineering is grounded in systematic diagramming and documentation standards:

- **[Visualizing Complex Systems](https://andypotanin.com/digital-rails-and-logistics/)**: Understanding software evolution through fluid dynamics and visual tracing.
- **[Mermaid Standards](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: High-fidelity synthetic enrichment for documentation.

---
_UDX DevSecOps Team_
