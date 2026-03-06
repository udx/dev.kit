---
name: dev-kit-core
description: PRIMARY orchestrator for the dev.kit ecosystem. Manages the engineering environment, validates health, synchronizes AI agent interfaces, and translates repository context into actionable AI prompts.
---

## Objective
Establish and maintain a high-fidelity, deterministic developer environment across hosts and repositories.

## CLI Usage Example
```bash
# Check environment health and identify missing integrations
dev.kit doctor

# Synchronize all AI skills and memories for Gemini
dev.kit agent gemini

# Start a new engineering task with context tracking
dev.kit task start --request "Integrate new security scanner"

# Execute a request with full repository context
dev.kit skills run "Audit this repo for Repo-as-a-Skill compliance"
```

## Primary Skill: Configure Developer Environment
The core capability of `dev.kit` is to establish and maintain a high-fidelity, deterministic developer environment. This includes:
- **Environment Bootstrapping**: Installing the CLI source, setting up shell integration, and managing pathing.
- **Orchestration**: Using `environment.yaml` to standardize configurations across different hosts.
- **Health & Security Monitoring**: Using `dev.kit doctor` to verify environment state and advise on sensitive variable safety.
- **Interface Translation**: Mapping repository-scoped skills (`src/*`), rules, and context into a unified interface for humans and AI agents.

## Core Interface (CLI Primitives)
- `dev.kit status`: High-fidelity engineering brief (Default).
- `dev.kit agent`: Manage and synchronize AI agent environments (Gemini, Codex).
- `dev.kit task`: Manage deterministic task iteration and workflows.
- `dev.kit skills run`: Execute standardized prompts with full repo context.
- `dev.kit config`: Show or set global/repo configurations.
- `dev.kit doctor`: Verify environment health and security.

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
- Repository skills are correctly mapped to the AI agent via `dev.kit ai apply`.
- `dev.kit doctor` reports `[ok]` for all critical integration points.

---
_UDX DevSecOps Team_
