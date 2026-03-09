# Context-Driven Engineering (CDE): Resolving the Drift

**Domain:** Foundations / Core Philosophy  
**Status:** Canonical

## Summary

**Context-Driven Engineering (CDE)** is the foundational methodology of **dev.kit**. It transforms chaotic user intent into executable context by treating the repository as the **Single Source of Truth**. CDE provides the structural framework for identifying and **Resolving the Drift** between intent and reality.

**dev.kit** operates as the **Thin Empowerment Layer** (Grounding Bridge) that projects this philosophy into a dynamic "Skill Mesh" accessible to humans and AI agents.

![CDE Flow](../../assets/diagrams/cde-flow.svg)

---

## Core Principles: The Operational DNA

These principles guide every architectural decision in the ecosystem:

1.  **Resolve the Drift**: Every action must purposefully close the gap between intent and repository state.
2.  **Deterministic Normalization**: Distill chaotic inputs into bounded, repeatable workflows before execution.
3.  **Resilient Waterfall (Fail-Open)**: Never break the flow. Fallback to standard raw data if specialized tools fail.
4.  **Repo-Scoped Truth**: The repository is the absolute, versioned source of truth for all skills and state.
5.  **Validated CLI Boundary**: All execution occurs through a hardened CLI interface for explicit confirmation and auditability.
6.  **Symmetry of Artifacts**: Every output must be equally legible to humans (Markdown) and consumable by machines (YAML/JSON).

---

## The Three Pillars of Empowerment

### 1. Grounding (The Bridge)
Ensures that every engineering action is grounded in the repository's truth. It audits the environment and synchronizes AI context to ensure alignment with repository rules.

### 2. Normalization (The Filter)
Chaotic user requests are filtered through a **Normalization Boundary**. Ambiguous intent is distilled into a deterministic `workflow.md` plan before any execution occurs.

### 3. Execution (The Engine)
Logic is executed through modular, standalone scripts and CLI commands. `dev.kit` ensures these run in a consistent, environment-aware context.

---

## Architecture: The Thin Layer

`dev.kit` distinguishes between **Deterministic Functions** (the programmatic logic) and **AI Reasoning Skills** (the dynamic intent resolution).

### 1. Deterministic Functions (The Engine)
Hardened, predictable routines found in `lib/commands/` and `docs/skills/*/assets/`.
- **Role**: Execute specific, bounded actions with high fidelity (e.g., atomic commits, SVG rendering).

### 2. AI Reasoning Skills (The Brain)
Dynamic capabilities defined in `SKILL.md`. They use LLM reasoning to bridge unstructured intent with repository functions.
- **Role**: Interpret intent, analyze repository state, and orchestrate the engine.

---

## The Skill Mesh

The entire repository is treated as a **Skill**. The mesh is dynamically discovered by scanning:
- **Internal Commands**: Metadata-rich shell scripts in `lib/commands/`.
- **AI Reasoning Skills**: Authoritative `SKILL.md` files in `docs/skills/`.
- **Functional Assets**: Programmatic templates and configs managed by the engine.
- **Virtual Capabilities**: Global environment tools (`gh`, `npm`, `worker`).

---

## 📚 Authoritative References

CDE is grounded in foundational research on high-fidelity automation:

- **[AI-Powered Revolution in Content Management](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: High-fidelity synthetic enrichment.
- **[The Power of Automation](https://andypotanin.com/the-power-of-automation-how-it-has-transformed-the-software-development-process/)**: Systematic transformation of the engineering flow.
- **[Observation-Driven Management (ODM)](https://andypotanin.com/observation-driven-management-revolutionizing-task-assignment-efficiency-workplace/)**: Optimizing efficiency through AI-identified patterns.

---
_UDX DevSecOps Team_
