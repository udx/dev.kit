# dev.kit Workflow Mesh: Intent-to-Resolution

**Domain:** Foundations / Workflows  
**Status:** Canonical

## Summary

The **Workflow Mesh** is the collection of deterministic sequences and dynamic reasoning patterns used to resolve repository drift. It bridges the gap between chaotic user intent and the high-fidelity execution engine.

---

## 🏗 Workflow Hierarchy

1.  **[Normalization](normalization.md)**: The mapper that transforms intent into bounded plans.
2.  **[Engineering Loops](loops.md)**: Standardized sequences for features, bugfixes, and discovery.
3.  **[Git Synchronization](git-sync.md)**: Logical grouping and atomic commit orchestration.
4.  **[Visual Engineering](visualizer.md)**: AI-driven architectural diagramming and flow analysis.

---

## ⚙️ Managed Assets

Common logic and templates used by the mesh are stored in the `assets/` directory:
- **`assets/git-sync.yaml`**: The canonical synchronization sequence.
- **`assets/templates/`**: Standard Mermaid patterns for visual engineering.

## 🏗 Mesh Grounding

The Workflow Mesh is operationalized through canonical UDX resources:

| Requirement | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Logic** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | Dynamic discovery and orchestration engine. |
| **Runtime** | [`udx/worker`](https://github.com/udx/worker) | Deterministic environment for workflow execution. |
| **Patterns** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Pattern baseline for cross-repo sequences. |

---

## 🛠 Synchronization
Agents hydrate their environment by running **`dev.kit ai sync`**. This process scans the mesh for high-fidelity documentation and projects metadata into the agent's active context.

---

## 📚 Authoritative References

The Workflow Mesh is grounded in foundational patterns for delivery flow and task management:

- **[Predictable Delivery Flow](https://andypotanin.com/littles-law-applied-to-devops/)**: Managing cycle time through systematic sequences.
- **[Observation-Driven Management](https://andypotanin.com/observation-driven-management-revolutionizing-task-assignment-efficiency-workplace/)**: Optimizing task assignment through pattern identification.

---
_UDX DevSecOps Team_
