# 12-Factor (Applied): High-Fidelity Engineering

**Domain:** Reference / Standards  
**Status:** Canonical

## Summary

The 12-Factor App methodology provides the foundational principles for modern, cloud-native engineering. In **dev.kit**, these principles are enforced at the repository level to ensure every project is a portable, high-fidelity "Skill."

---

## 🛠 dev.kit Grounding: Principle-to-Primitive Mapping

| 12-Factor Principle | dev.kit Implementation | Primitive / Command |
| :--- | :--- | :--- |
| **I. Codebase** | One repository, multiple deployments (Local, CI, Prod). | `dev.kit sync` |
| **II. Dependencies** | Explicit and isolated via the Worker Ecosystem. | `dev.kit doctor` |
| **III. Config** | Stored in the environment (YAML/Env). | `environment.yaml` |
| **IV. Backing Services** | Resolved as "Virtual Skills" (NPM/GitHub/Context7). | `dev.kit ai skills` |
| **V. Build, Release, Run** | Strict separation of grounding and execution phases. | `dev.kit ai sync` |
| **VI. Processes** | Stateless and share-nothing; context is externalized. | `.udx/dev.kit/tasks/` |
| **IX. Disposability** | Fast startup and clean cleanup of stagnant state. | `dev.kit task cleanup` |
| **X. Dev/Prod Parity** | Identical runtimes via high-fidelity Worker images. | `udx/worker` |
| **XII. Admin Processes** | One-off tasks executed as bounded workflows. | `dev.kit skills run` |

---

## 🏗 High-Fidelity Mandates

### 1. Externalize All State
Never store mutable task state in the root of the repository. All engineering context must be externalized to the hidden **State Hub**.
- **Action**: Use `get_repo_state_dir` to resolve `.udx/dev.kit/` for all local state.

### 2. Explicit Dependency Resolution
A repository is only high-fidelity if its dependencies are discoverable and verified.
- **Action**: Maintain `environment.yaml` and use `dev.kit doctor` to verify the **Skill Mesh**.

### 3. Environment-Aware Configuration
Favor `environment.yaml` for shared orchestration and `.env` for local secrets. Never commit sensitive credentials.
- **Action**: Ensure `.udx/` and `.env` are in `.gitignore`.

---

## Operational Cues

- **Drift Detected?** -> Run `dev.kit sync run` to restore 12-factor codebase integrity.
- **Missing Tooling?** -> Consult the **Skill Mesh** via `dev.kit status` to resolve the gap.

## 📚 Authoritative References

12-Factor principles are extended through systematic environment automation:

- **[12-Factor Environment Automation](https://udx.io/devops-manual/12-factor-environment-automation)**: Deep dive into cloud-native configuration strategy.
- **[12factor.net](https://12factor.net/)**: The original methodology for building software-as-a-service.
- **[Decentralized DevOps](https://andypotanin.com/how-decentralized-devops-can-help-your-organization/)**: Scaling organizations through distributed service architectures.
- **[Navigating to the Cloud](https://andypotanin.com/windows-to-cloud/)**: Managing the complexity of modern cloud IT systems.

---
_UDX DevSecOps Team_
