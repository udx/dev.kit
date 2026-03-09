# Runtime Overview: The Deterministic Engine

**Domain:** Runtime / CLI  
**Status:** Canonical

## Summary

The **dev.kit** CLI is the deterministic engine designed to resolve the **Drift** between human intent and repository reality. It provides a hardened boundary for executing repository-bound skills while maintaining high-fidelity environment health.

---

## 🐳 Runtime Environment

To ensure deterministic behavior and context fidelity, **dev.kit** is optimized for the **UDX Worker Ecosystem**.

- **Primary Target**: `usabilitydynamics/udx-worker:latest`.
- **Orchestration**: Sessions follow the `udx/worker-deployment` patterns.
- **Isolated Execution**: Testing and high-stakes operations should always be performed within a clean `udx/worker` container to eliminate local drift.

---

## 🚀 Entry Points

- **`bin/dev-kit`**: The primary dispatch entrypoint. Loads internal helpers and routes subcommands.
- **`bin/env/dev-kit.sh`**: Shell initialization (Banner, PATH setup, and completions).
- **`bin/scripts/install.sh`**: High-fidelity installer with safe-mode and backups.
- **`bin/scripts/uninstall.sh`**: Simple uninstaller with optional state purging.


---

## 🛠 Deterministic Commands

### Status & Discovery
- **`dev.kit status`**: (Default) High-fidelity engineering brief and task visibility.
- **`dev.kit suggest`**: Suggest repository improvements and CDE compliance fixes.
- **`dev.kit doctor`**: Deep system analysis, environment hydration, and compliance audit.


### AI & Skill Mesh
- **`dev.kit ai`**: Unified agent integration management, skill synchronization, and grounding.
- **`dev.kit skills`**: Discovery and execution of repository-bound skills.

### Task & Lifecycle
- **`dev.kit sync`**: Logical, atomic repository synchronization and drift resolution.
- **`dev.kit task`**: Manage the lifecycle of active workflows and engineering sessions.
- **`dev.kit config`**: Scoped orchestration via `environment.yaml` and `.env`.

---

## 🧩 Dynamic Discovery Engine

`dev.kit` does not rely on static metadata. It dynamically discovers capabilities by scanning:
1.  **Internal Commands**: Metadata-rich scripts in `lib/commands/*.sh`.
2.  **Managed Skills**: Specialized toolsets in `docs/skills/`.
3.  **Virtual Skills**: External CLI tools (gh, npm, docker) detected in the environment.
## 🏗 Engine Grounding

The `dev.kit` engine is grounded in core UDX infrastructure to ensure high-fidelity execution:

| Component | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Runtime** | [`udx/worker`](https://github.com/udx/worker) | Standardized, pre-hydrated base environment. |
| **API Mesh** | [`@udx/mcurl`](docs/ai/mesh/npm.md) | High-fidelity API interaction and error handling. |
| **Orchestration**| [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Deterministic CI/CD and deployment patterns. |

---

## 📚 Authoritative References

Deterministic CLI orchestration is built on systematic engineering flow and portability:

- **[Automotive Software Evolution](https://andypotanin.com/digital-rails-and-logistics/)**: Tracing the evolution of deterministic algorithms through automotive innovation.
- **[Decentralized DevOps](https://andypotanin.com/how-decentralized-devops-can-help-your-organization/)**: Using distributed services to create scalable and portable systems.

---
_UDX DevSecOps Team_
