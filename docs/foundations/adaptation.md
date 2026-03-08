# Context Adaptation: Resilient Projections

**Domain:** Concepts / Technical Bridge  
**Status:** Canonical

## Summary

**Adaptation** is the mechanism `dev.kit` uses to project canonical repository sources into tool-specific formats without mutating the underlying intent. It serves as the technical bridge for **Resilient Normalization**, ensuring that repository "Skills" are consumable by any agent or engine while the source remains "Clean" and "Native."

![Adaptation Flow](../../assets/diagrams/adaptation-flow.svg)

---

## The Purpose of Adaptation

- **Interface Normalization**: Projecting standard repository artifacts (Markdown/YAML) into machine-consumable schemas (e.g., JSON manifests for LLM Tool-Calling or IDE-specific configs).
- **Resilient Fallback**: Ensuring that if a specialized projection fails, the system automatically falls back to **Standard Data** (e.g., raw Markdown or Text) to prevent a "hard-stop" in the engineering flow.
- **Canonical Integrity**: Ensuring that all drift is resolved at the repository level. Tools may change, but the **Source of Truth** (the Repo) remains constant.

---

## The Laws of Adaptation

1.  **Canonical First**: Never edit a projection to fix a bug. Resolve the drift in the repository's source artifacts and re-project.
2.  **Ephemeral Reversibility**: Adaptations are non-destructive projections. It must always be possible to delete all adapted formats and regenerate them perfectly from the source.
3.  **Fail-Open Logic**: If an adaptation engine (e.g., a Mermaid-to-SVG renderer) is missing, the system must "Fail-Open" by providing the raw source to the user or agent rather than blocking the sequence.

---

## Practical Examples: Source → Projection

| Source Artifact        | Projection Target | Adaptation Logic                                                                         |
| :--------------------- | :---------------- | :--------------------------------------------------------------------------------------- |
| **`environment.yaml`** | Shell Environment | Translates YAML keys into host-specific `$ENV` variables and aliases.                    |
| **`docs/skills/*.md`** | Agent Manifests   | Extracts `@intent` and `@usage` metadata into JSON for LLM tool-calling.                 |
| **`.mmd` (Mermaid)**   | `.svg` or `.png`  | Renders visual diagrams for documentation (Falls back to raw code if `mmdc` is missing). |
| **Script Headers**     | CLI Help Menus    | Parses shell script comments into a dynamic `dev.kit --help` interface.                  |

## 🏗 Adaptation Primitives

To ensure high-fidelity projections, `dev.kit` leverages canonical UDX resources as the targets for intent normalization:

| Primitive | Adaptation Goal | Target Source |
| :--- | :--- | :--- |
| **Workflow Logic** | Project intent into reusable CI/CD patterns. | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) |
| **Runtime Context** | Normalize environment parity across containers. | [`udx/worker`](https://github.com/udx/worker) |
| **Plugin Evolution** | Scale high-fidelity WordPress integrations. | [`udx/wp-stateless`](https://github.com/udx/wp-stateless) |

---

## The Adaptation Lifecycle

1.  **Discovery**: `dev.kit` scans the repository for high-fidelity Markdown and YAML.
2.  **Mapping**: The system determines the required "Shape" based on the current consumer (e.g., an AI Agent vs. a Local Developer).
3.  **Projection**: The artifact is rendered into the ephemeral target format.
4.  **Verification**: The system ensures the projection accurately reflects the **Canonical Intent**.

## 📚 Authoritative References

Resilient projections are a core part of maintaining standalone quality across disparate formats:

- **[Synthetic Content Enrichment](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: Strategies for maintaining quality when projecting content across systems.
- **[Digital Logistics](https://andypotanin.com/digital-rails-and-logistics/)**: Tracing the evolution of software through the lens of fluid dynamics and systematic tracing.

---
_UDX DevSecOps Team_
