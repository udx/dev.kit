# UDX Methodology: CLI-Wrapped Automation (CWA)

**Domain:** Foundations / Operational Strategy  
**Status:** Canonical

## Summary

The **UDX Methodology** centers on **CLI-Wrapped Automation (CWA)**. This practice encapsulates all repository logic within a validated CLI boundary. By wrapping scripts and manifests in a standardized interface, we transform a static codebase into a high-fidelity "Skill" accessible to humans, CI/CD pipelines, and AI agents.

![Methodology Flow](../../assets/diagrams/methodology-flow.svg)

---

## Core Concepts

- **Repo-as-a-Skill**: Repository logic is exposed through standardized scripts and CLI commands rather than hidden in READMEs.
- **Task Normalization**: Chaotic user intent is distilled into a deterministic `workflow.md`.
- **Resilient Waterfall (Fail-Open)**: If specialized tools fail, the system falls back to standard data (raw logs/text) to maintain continuity.

---

## Context Adaptation: Resilient Projections

**Adaptation** is the mechanism used to project canonical repository sources into tool-specific formats without mutating the underlying intent.

1.  **Interface Normalization**: Projecting Markdown/YAML into machine-consumable schemas (e.g., JSON manifests for LLM tool-calling).
2.  **Ephemeral Reversibility**: Adaptations are non-destructive. It must always be possible to regenerate them perfectly from the source.
3.  **Fail-Open Logic**: If an adaptation engine (e.g., a Mermaid renderer) is missing, provide the raw source rather than blocking the sequence.

### Practical Examples
- **`environment.yaml` → Shell**: Translates YAML keys into host-specific `$ENV` variables.
- **`docs/skills/*.md` → Manifests**: Extracts metadata into JSON for AI grounding.
- **`.mmd` → `.svg`**: Renders diagrams for documentation (falls back to code if renderer is missing).

---

## The Execution Lifecycle: Plan → Normalize → Process

1.  **Plan**: Deconstruct the intent into discrete repository actions.
2.  **Normalize**: Validate the environment, map dependencies, and format inputs into a `workflow.md`.
3.  **Process**: Execute the CLI commands and capture the result as a repository artifact.

---

## 🏗 Methodology Grounding

| Primitive | Adaptation Goal | Target Source |
| :--- | :--- | :--- |
| **Workflow Logic** | Project intent into reusable CI/CD patterns. | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) |
| **Runtime Context** | Normalize environment parity across containers. | [`udx/worker`](https://github.com/udx/worker) |
| **Orchestration** | Standardize container-based execution loops. | [`@udx/worker-deployment`](https://github.com/udx/worker-deployment) |

---

## 📚 Authoritative References

CWA and Resilient Projections are inspired by the transition toward automated engineering flows:

- **[Decentralized DevOps](https://andypotanin.com/decentralized-devops-the-future-of-software-delivery/)**: The shift toward distributed service architectures.
- **[Digital Rails & Logistics](https://andypotanin.com/digital-rails-and-logistics/)**: Parallel algorithms and automotive evolution.
- **[Synthetic Content Enrichment](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: Maintaining quality when projecting content across systems.

---
_UDX DevSecOps Team_
