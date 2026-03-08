# dev.kit Skill Mesh: AI Reasoning & Orchestration

**Domain:** AI / Skill Mesh  
**Status:** Canonical

## Summary

The **Skill Mesh** is the library of dynamic reasoning toolsets used by AI agents to resolve repository drift. Unlike **Deterministic Commands** (found in `lib/commands/`), which provide the core programmatic engine, **Skills** represent the AI's ability to reason about unstructured intent and orchestrate these commands to achieve high-fidelity results.

---

## 🏗 Skill Structure

Every skill in this directory is a self-contained package consumable by the **Dynamic Discovery Engine**:

- **`SKILL.md`**: The authoritative definition of the skill's intent, capabilities, and primitives.
- **`assets/`**: (Optional) Templates, schemas, or static resources managed by the skill.
- **`scripts/`**: (Optional) Dynamic reasoning logic or specialized AI-driven scripts.

---

## 🚀 Managed Skills

The following skills are currently active in the repository:

- **[Visualizer](dev-kit-visualizer/SKILL.md)**: AI-driven architectural diagramming and flow analysis.
- **[Git Sync](dev-kit-git-sync/SKILL.md)**: Dynamic grouping and atomic commit orchestration.

---

## 🛠 Grounding & Sync

Agents hydrate their environment by running **`dev.kit ai sync`**. This process:
1.  **Scans** this directory for `SKILL.md` files.
2.  **Renders** metadata into agent-specific manifests.
3.  **Projections**: Copies the skill packages into the agent's active context (e.g., `~/.gemini/skills/`).

---

## 📚 Authoritative References

The Skill Mesh is grounded in foundational patterns for repository-centric intelligence:

- **[Synthetic Content Enrichment](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: High-fidelity metadata management for documentation.
- **[Autonomous Technical Operations](https://andypotanin.com/claude-operator-prompt/)**: Principles for high-fidelity agent grounding and execution.

---
_UDX DevSecOps Team_
