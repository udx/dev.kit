# Configuration: Environment Orchestration

**Domain:** Runtime / Configuration  
**Status:** Canonical

## Summary

Configuration in **dev.kit** provides a safe, deterministic foundation for both humans and agents. It maps host-level settings and repository metadata into a high-fidelity engineering interface using `environment.yaml`.

---

## Configuration Strategy

- **Agent Bootstrapping**: Configuration is the first gate where AI agents are safely hydrated with repository rules and authorized execution paths.
- **Task Orchestration**: Scoped settings ensure that normalized workflows have a consistent and isolated runtime context across diverse environments.

---

## CLI Interfaces

- **`dev.kit config show`**: View active host and repository configuration.
- **`dev.kit config set --key <key> --value <value>`**: Update a specific setting.
- **`dev.kit config reset`**: Revert to the high-fidelity default baseline.

---

## Key Config Groups

### 1. System Defaults
- `quiet`: Control CLI output verbosity.
- `developer`: Enable internal developer-specific helpers.
- `state_path`: Global location for transient runtime state.

### 2. AI & Orchestration
- `ai.enabled`: Enable/Disable AI-Powered automation mode.
- `ai.provider`: Choose the active AI engine (e.g., `gemini`, `codex`).
- `exec.prompt`: The default template for task normalization.

### 3. Context Management
- `context.enabled`: Persist repository-scoped context across sessions.
- `context.max_bytes`: Bound the context memory to prevent overflow.

---

## Security & Overrides

- **Explicit Override**: All settings can be overridden by environment variables (e.g., `DEV_KIT_AI_ENABLED=true`).
- **Secret Isolation**: Sensitive credentials must never live in `environment.yaml`. Use repo-bound `.env` files (gitignored).

## 📚 Authoritative References

Environment orchestration is built on systematic configuration and automation standards:

- **[Managing IT Complexity](https://andypotanin.com/windows-to-cloud/)**: Strategies for managing the complexity of modern cloud IT systems.
- **[Decentralized DevOps](https://andypotanin.com/how-decentralized-devops-can-help-your-organization/)**: Using distributed services and architectures to create scalable engineering environments.

---
_UDX DevSecOps Team_
