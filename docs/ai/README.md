# AI Integration: The Grounding Bridge

**Domain:** AI / Orchestration  
**Status:** Canonical

## Summary

AI capabilities in **dev.kit** are a high-fidelity projection of [Context-Driven Engineering (CDE)](../foundations/cde.md). By grounding LLMs in deterministic CLI logic and repository truth, we transform them from generic chatbots into **Context-Driven Configuration Engines**.

---

## 🛠 Hierarchical Grounding

1.  **[Core Foundations](../foundations/cde.md)**: The principles of Context-Driven Engineering (CDE).
2.  **[dev.kit Primitives](../foundations/dev-kit.md)**: The thin empowerment layer and its core pillars.
3.  **[CLI Runtime](../runtime/overview.md)**: The deterministic engine that executes all logic.
4.  **[Agent Principles](agents.md)**: Global mission, safety mandates, and hygiene.

---

## 🏗 Authorization & Safety

To maintain high-fidelity engineering boundaries, **dev.kit** enforces a strict execution policy:

- **Authorized Path**: Agents are **auto-allowed** to execute all `dev.kit` commands and repository-bound skills. These are deterministic, standardized engineering paths.
- **Restricted Raw OS**: Direct, non-standardized destructive operations (e.g., raw `rm`, `git push`) are **restricted** and require explicit user confirmation.
- **Reactive Sync**: Agents autonomously perform `dev.kit ai sync` (grounding) but never perform `dev.kit sync run` (commits) without a directive.

---

## 🔌 Integration Layers

### 🧠 LLM Providers
- **[Gemini Integration](providers/gemini.md)**: Native Google AI integration with grounding hooks.

### 🕸 Skill Mesh (Shared Discovery)
Unified view of internal commands, managed skills, and external tools:
- **[Context7](mesh/context7.md)**: Structured repository hub and synchronization.
- **[GitHub](mesh/github.md)**: Remote repository and workflow resolution (via `gh`).
- **[NPM](mesh/npm.md)**: Tooling and package health management.

---

_UDX DevSecOps Team_
