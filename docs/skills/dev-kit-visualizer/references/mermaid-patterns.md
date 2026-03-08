# Mermaid Patterns: Visual Standards

**Domain:** Visual Engineering / Standards  
**Status:** Canonical

## Summary

This reference provides standardized patterns for Mermaid-based visualizations within the `dev.kit` ecosystem. These patterns ensure that architecture and process flows are consistent, version-controlled, and legible to both humans and agents.

---

## 🏗 Type Selection

- **`flowchart`**: Use for process steps, service interactions, and decision gates.
- **`sequenceDiagram`**: Use for time-ordered interactions between actors or multi-turn execution loops.
- **`stateDiagram-v2`**: Use for state transitions with explicit events and lifecycle stages.
- **`erDiagram`**: Use for entity relationships and data cardinality.

---

## 📝 Conventions

- **Identifier Stability**: Maintain consistent IDs during revisions to ensure clean diffs.
- **Labeling**: Prefer short, action-oriented node labels; use edge labels for details.
- **Domain Separation**: Split diagrams when crossing functional boundaries (e.g., separate API flow from deployment flow).
- **Horizontal Priority**: Favor `flowchart LR` to optimize vertical space in Markdown documentation.

---

## ⚙️ Deterministic Logic (Export)

- **Fail-Open**: If `mmdc` fails, always provide the raw Mermaid source to the user/agent.
- **Sandboxing**: In restricted environments, leverage Puppeteer `--no-sandbox` flags via local configuration.

---

## 📚 Authoritative References

Visual standards are a core part of maintaining standalone documentation quality:

- **[Synthetic Content Enrichment](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: High-fidelity metadata management and visual standards.
- **[Visual Tracing & Logistics](https://andypotanin.com/digital-rails-and-logistics/)**: Drawing parallels between software algorithms and visual process dynamics.

---
_UDX DevSecOps Team_
