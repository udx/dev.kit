---
name: dev-kit-core
description: Configure, manage, and verify the developer engineering environment. Acts as the primary orchestrator and translator for all repository skills and tools.
---

## Primary Skill: Configure Developer Environment
The core capability of `dev.kit` is to establish and maintain a high-fidelity, deterministic developer environment. This includes:
- **Environment Bootstrapping**: Installing the CLI source, setting up shell integration, and managing pathing.
- **Orchestration**: Using `environment.yaml` to standardize configurations across different hosts.
- **Health & Security Monitoring**: Using `dev.kit doctor` to verify environment state and advise on sensitive variable safety.
- **Interface Translation**: Mapping repository-scoped skills (`src/*`), rules, and context into a unified interface for humans and AI agents.

## Core Interface (CLI Primitives)
- `dev.kit config`: Show or set global/repo configurations.
- `dev.kit doctor`: Verify environment health and security.
- `dev.kit task`: Manage deterministic task iteration and workflows.
- `dev.kit codex`: Map repository skills to the global AI agent.
- `dev.kit exec`: Execute standardized prompts with full repo context.

## Deterministic Mapping Logic
- **Priority 1**: `environment.yaml` (Orchestrator)
- **Priority 2**: `.udx/dev.kit/config.env` (Local Repo)
- **Priority 3**: `~/.udx/dev.kit/state/config.env` (Global User)

## Usage as a Translator
When acting as a translator, `dev.kit` must:
1.  **Resolve Context**: Identify the current repository root and any active task state.
2.  **Load Orchestrator**: Read `environment.yaml` to determine the active AI mapping and system settings.
3.  **Translate Request**: Convert the user's intent into a specific CLI command or a structured prompt artifact.
4.  **Enforce CWA**: Ensure all execution follows the CLI-Wrapped Automation methodology (Plan -> Normalize -> Process).

## Success Criteria
- Environment variables are correctly set (`DEV_KIT_HOME`, `DEV_KIT_STATE`, etc.).
- Shell auto-init is active and completions are functional.
- Repository skills are correctly mapped to the AI agent via `dev.kit codex apply`.
- `dev.kit doctor` reports `[ok]` for all critical integration points.
