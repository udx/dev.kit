# dev.kit: The Thin Empowerment Layer

**Domain:** Foundations / Core Concept  
**Status:** Canonical

## Summary

**dev.kit** is a high-fidelity engineering interface designed to resolve the **Drift** between human intent and repository reality. It operates as a **Thin Empowerment Layer** (Grounding Bridge) that transforms a static codebase into a dynamic "Skill Mesh" accessible to humans and AI agents alike.

---

## Core Philosophy

`dev.kit` is built on the principles of **Context-Driven Engineering (CDE)**. It does not replace your existing tools; it orchestrates them to maintain a deterministic, context-aware engineering environment.

- **Non-Proprietary**: Uses standard Markdown, YAML, and Shell scripts.
- **Deterministic**: Every action is bounded by a validated CLI interface.
- **Agent-Ready**: Provides native "Grounding" for LLMs, transforming them into configuration engines.

---

## The Three Pillars of dev.kit

### 1. Grounding (The Bridge)
`dev.kit` provides the necessary context to ensure that every engineering action is grounded in the repository's truth. It audits the environment (`dev.kit doctor`) and synchronizes AI context (`dev.kit ai sync`).

### 2. Normalization (The Filter)
Chaotic user requests are filtered through a **Normalization Boundary**. Ambiguous intent is distilled into a deterministic `workflow.md` plan before any execution occurs.

### 3. Execution (The Engine)
Logic is executed through modular, standalone scripts and CLI commands. `dev.kit` ensures these run in a consistent, environment-aware context via `environment.yaml`.

## Architecture: The Empowerment Layer

`dev.kit` distinguishes between **Deterministic Functions** (the programmatic logic) and **AI Reasoning Skills** (the dynamic intent resolution).

### 1. Deterministic Functions (The Engine)
These are hardened, predictable routines found in `lib/commands/` and `docs/skills/*/assets/`. They provide the execution engine for the repository.
- **Example (Git Sync)**: The `workflow.yaml` and `git_sync.sh` logic that groups files and executes commits.
- **Example (Visualizer)**: The Mermaid templates and `mmdc` export logic that renders SVGs.
- **Role**: Execute specific, bounded actions with high fidelity.

### 2. AI Reasoning Skills (The Brain)
These are the dynamic capabilities defined in `SKILL.md`. They use LLM reasoning to bridge unstructured intent with repository functions.
- **Example (Git Sync)**: Analyzing a set of changed files to **determine the logical domains** (docs, cli, core) and generate a meaningful commit message.
- **Example (Visualizer)**: Reading a README or source file to **extract the logical process flow** and map it to a specific Mermaid template.
- **Role**: Interpret intent and orchestrate the engine.

---

## The Skill Mesh

`dev.kit` treats the entire repository as a **Skill**. It dynamically discovers the mesh by scanning:
- **Internal Commands**: Metadata-rich shell scripts in `lib/commands/`.
- **AI Reasoning Skills**: Authoritative `SKILL.md` files in `docs/skills/`.
- **Functional Assets**: Programmatic templates and configs managed by the engine.
- **Virtual Capabilities**: Global environment tools (`gh`, `npm`, `docker`).

---

## Primary Interfaces

- **`dev.kit status`**: The "Engineering Brief." High-signal overview of health and active tasks.
- **`dev.kit ai`**: The "Grounding Layer." Orchestrates AI integration and skill synchronization.
- **`dev.kit sync`**: The "Drift Resolver." Atomic, domain-specific repository synchronization.
- **`dev.kit task`**: The "Lifecycle Manager." Tracks intent from normalization to resolution.

## 📚 Authoritative References

The mission of dev.kit is grounded in the practical need for high-fidelity engineering empowerment:

- **[Jumping into Dev at a Software Enterprise](https://andypotanin.com/dev-start/)**: Guidance for starting the engineering journey with specialized tools.
- **[Navigating to the Cloud](https://andypotanin.com/windows-to-cloud/)**: Managing the complexity of modern cloud IT systems.

---
_UDX DevSecOps Team_

