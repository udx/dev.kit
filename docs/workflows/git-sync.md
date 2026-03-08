# Skill: dev-kit-git-sync

**Domain:** Source Control / Synchronization  
**Type:** AI Reasoning Skill  
**status:** Canonical

## Summary

The **Git Synchronization** skill enables AI agents to resolve repository drift by logically grouping and committing changes. It uses dynamic reasoning to categorize modifications into high-fidelity domains (docs, ai, cli, core) and generates context-rich commit messages.

---

## 🛠 AI Reasoning (The Skill)

This skill utilizes dynamic LLM reasoning to perform the following:
- **Logical Domain Determination**: Analyzing changed files to map them to high-fidelity domains (docs, ai, cli, core).
- **Contextual Intent Capture**: Generating meaningful commit messages that reflect the "Why" behind the drift resolution.
- **Drift Identification**: Recognizing unstaged changes and determining the correct synchronization sequence.
- **Collaborative Orchestration**: Identifying when a task is ready for review and proactively suggesting the creation of a Pull Request.

---

## ⚙️ Deterministic Logic (Function Assets)

The following assets provide the programmatic engine for this skill:
- **`workflow.yaml`**: The canonical definition of synchronization steps and grouping rules.
- **Atomic Committer**: Hardened logic that ensures changes are committed in discrete, revertible blocks.
- **PR Suggestion Engine**: Proactive prompt that interfaces with the **GitHub Mesh** to create remote Pull Requests.

## 🏗 Sync Grounding

Git synchronization is operationalized through canonical UDX resources:

| Requirement | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Atomic Logic** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | The primary engine for logical grouping and commits. |
| **Workflow Pattern** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Pattern baseline for remote sync and CI/CD. |
| **Collaboration** | [`ai/mesh/github.md`](../ai/mesh/github.md) | Grounding for PR creation and remote resolution. |

---

## 🚀 Primitives Orchestrated

This skill is grounded in the following **Deterministic Primitives**:
- **`dev.kit sync prepare`**: Prepares feature branches and synchronizes with origin.
- **`dev.kit sync run`**: Executes atomic commits and resolves drift.

---

## 📂 Managed Assets

- **Workflow YAML**: Canonical synchronization sequence in `docs/workflows/assets/git-sync.yaml`.

---

## 📚 Authoritative References

High-fidelity synchronization is grounded in systematic SDLC and version control practices:

- **[Predictable Delivery Flow](https://andypotanin.com/littles-law-applied-to-devops/)**: Managing Work-in-Progress (WIP) through atomic, domain-specific commits.
- **[Decentralized DevOps](https://andypotanin.com/decentralized-devops-the-future-of-software-delivery/)**: The shift toward distributed architectures and automated synchronization.

---
_UDX DevSecOps Team_
