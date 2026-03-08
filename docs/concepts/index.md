# Engineering Concepts: The foundations of dev.kit

Domain: Concepts

## Summary

The Engineering Concepts provide a conceptual framework for **Resolving the Drift** and maintaining a high-fidelity environment. They describe "how" dev.kit thinks and acts as a **Smart Helper**.

## Core Topics

### 1. Methodology (CWA)
**CLI-Wrapped Automation (CWA)** is the practice of wrapping every repository skill in a validated CLI. This ensures that scripts that work locally work everywhere—for both humans and AI agents.
- **Key Doc**: `docs/concepts/methodology.md`

### 2. Context Driven Engineering (CDE)
**CDE** is the model for identifying and resolving drift. It treats intent, skills, and logic as concrete, versioned artifacts, enabling deterministic task execution.
- **Key Doc**: `docs/concepts/cde.md`

### 3. Context Adaptation
**Adaptation** projects canonical repository sources into tool-specific formats (e.g., Gemini skill manifests) without losing the original intent. It enables the **Fail-Open Normalization** fallback logic.
- **Key Doc**: `docs/concepts/adaptation.md`

---
_UDX DevSecOps Team_
