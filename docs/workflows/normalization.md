# Task Normalization: Intent-to-Workflow Mapping

**Domain:** Foundations / Normalization  
**Status:** Canonical

## Summary

**Task Normalization** is the process of transforming ambiguous user intent into deterministic execution plans. In **dev.kit**, the AI agent acts as the primary **Mapper**, reasoning about the request and mapping it to the appropriate repository workflows and primitives.

---

## 🏗 The Normalization Mapper

The agent is responsible for dynamic prompt transformation. It receives intent from the user, identifies the required capabilities, and sends structured instructions to the `dev.kit` workflow engine.

### 1. Dynamic Suggestions (Incremental Experience)
Every normalization cycle includes a heuristic check of the repository and environment. The `dev.kit suggest` command is used to provide actionable feedback that improves CDE compliance.
- **Example**: Detecting missing documentation or unnormalized CI/CD configs.
- **Action**: Suggested fixes are included in the normalization context for the agent to consider.

### 2. Strict Mappings (Deterministic)
Used for well-defined engineering tasks where the path is predictable and hardened.
- **Example**: Git Synchronization, environment hydration (`config detect`), or diagram rendering.
- **Enforcement**: Direct mapping to `lib/commands/` or `docs/workflows/assets/*.yaml`.

### 3. Non-Strict Mappings (Reasoning-First)
Used for creative or complex tasks where the agent must reason about the best path before committing to a sequence.
- **Example**: Implementing a new feature, refactoring complex logic, or resolving multi-domain drift.
- **Enforcement**: The agent generates a custom `workflow.md` that orchestrates multiple primitives.


---

## 🔄 Dynamic Prompt Transformation

Agents are auto-mapped to send and receive context from repository workflows. If a task requires something outside of existing scripts or tools, the agent:
1.  **Reasons** about the implementation gap.
2.  **Generates** the necessary code or documentation patterns.
3.  **Packages** the resolution into a normalized `dev.kit` workflow step.

## 🏗 Standard Task Mapping

The normalization mapper routes common engineering intents to specialized UDX repositories:

| Intent Domain | Grounding Target | Mapping logic |
| :--- | :--- | :--- |
| **Containerization** | [`udx/worker`](https://github.com/udx/worker) | Normalize to base environment specs. |
| **Plugin Dev** | [`udx/wp-stateless`](https://github.com/udx/wp-stateless) | Normalize to structural plugin patterns. |
| **CI/CD / Actions** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Normalize to validated pipeline steps. |

---

## 🏗 Normalization Grounding

Task normalization is operationalized through canonical UDX resources:

| Requirement | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Logic Mapping** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | Dynamic discovery and task resolution engine. |
| **Context Hub** | [`docs/workflows/README.md`](README.md) | Source of truth for available repository sequences. |
| **Fidelity** | [`udx/worker`](https://github.com/udx/worker) | Deterministic runtime for validating normalized plans. |

---

## 📚 Authoritative References

Normalization ensures high-fidelity execution through systematic pattern recognition:

- **[Observation-Driven Management](https://andypotanin.com/observation-driven-management-revolutionizing-task-assignment-efficiency-workplace/)**: Optimizing task assignment through identified patterns.
- **[Autonomous Technical Operations](https://andypotanin.com/claude-operator-prompt/)**: Principles for high-fidelity agent grounding and execution.

---
_UDX DevSecOps Team_
