# GitHub Integration: Remote Discovery

**Domain:** AI / Remote Discovery  
**Status:** Canonical

## Summary

The GitHub integration enables **dev.kit** to perform high-fidelity **Discovery** by probing remote repositories, Pull Requests, and issues. By leveraging the `gh` CLI, it provides a grounded, authenticated interface for agents to interact with the broader engineering ecosystem.

---

## 🛠 Features & Capabilities

### 1. Skill Mesh Expansion
The GitHub integration allows the **Dynamic Discovery Engine** to identify and resolve skills located in remote repositories.
- **Trigger**: Intent resolution for an authorized organization or peer repository.
- **Outcome**: The AI can "reach out" to remote codebases to discover patterns or standardized workflows.

### 2. Triage & PR Management
- **Assigned Issues**: Fetches issues to ground the initial `task start` phase.
- **PR Lifecycle**: Authorizes agents to analyze and **create** Pull Requests to formalize drift resolution.

---

## 🏗 Requirements & Auth
- **CLI**: `gh` (GitHub CLI) must be installed and authenticated.
- **Auth**: Prefers `GH_TOKEN` or `GITHUB_TOKEN`. Falls back to interactive `gh auth login`.

## 🏗 Standard Resource Mapping

To maintain high-fidelity engineering flows, the GitHub integration prioritizes discovery across authoritative UDX repositories:

| Repository | Role | Purpose |
| :--- | :--- | :--- |
| **[`udx/reusable-workflows`](https://github.com/udx/reusable-workflows)** | CI/CD Baseline | Canonical GitHub Action patterns and deployment templates. |
| **[`udx/wp-stateless`](https://github.com/udx/wp-stateless)** | Plugin Core | Reference for high-fidelity WordPress cloud integrations. |
| **[`udx/worker-deployment`](https://github.com/udx/worker-deployment)** | Orchestration | Standard patterns for deploying and managing the Worker Ecosystem. |

---

## 🌊 Waterfall Progression (DOC-003)

**Progression**: `[github-mesh-active]`
- [x] Step 1: Detect and verify `gh` CLI health (Done)
- [>] Step 2: Resolve remote repository skills (Active)
- [ ] Step 3: Perform cross-repo intent normalization (Planned)

---
_UDX DevSecOps Team_
