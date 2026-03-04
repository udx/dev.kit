# Configuration: Orchestrating the Environment

Domain: Configuration

## Purpose

Configuration in **dev.kit** provides a safe, deterministic foundation for both humans and AI agents. It maps host-level settings into a high-fidelity engineering interface using `environment.yaml`.

## Configuration Strategy

- **Stage 1: AI Integration & Env Config**: Configuration is the first gate where AI agents are safely bootstrapped and rules are enforced.
- **Stage 2: Task Execution**: Config settings (e.g., `state_path`) ensure that normalized tasks have a consistent runtime context.

## CLI Interfaces

- `dev.kit config show`: View current host and repository configuration.
- `dev.kit config set --key <key> --value <value>`: Update a setting.
- `dev.kit config reset`: Revert to safe defaults.

## Key Config Groups

### 1. System Defaults
- `quiet`: Control output verbosity.
- `developer`: Enable developer-specific helpers.
- `state_path`: Location for runtime state (workflows, logs, cache).

### 2. AI & Orchestration
- `ai.enabled`: Enable/Disable AI-Powered mode.
- `ai.provider`: Choose the AI engine (Codex, Gemini, Claude).
- `exec.prompt`: The default prompt template for task normalization.

### 3. Context Management
- `context.enabled`: Persist repo-scoped context across turns.
- `context.max_bytes`: Bound the context memory size.

## Reset and Safety

- **Reset to Safe**: `dev.kit config reset` reverts to known-good defaults.
- **Explicit Override**: All settings in `environment.yaml` can be overridden by environment variables (e.g., `DEV_KIT_AI_ENABLED=true`).

---
_UDX DevSecOps Team_
