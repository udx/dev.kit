# dev.kit — Smart Engineering Interface Translator

Deterministic developer workflow kit for humans + AI. Its primary skill is to **Configure the Developer Engineering Environment** and translate repository capabilities into a standardized interface.

## The Bigger Picture

1.  **Repo is a Skill**: Every repository exposes its capabilities through structured scripts and CLI commands.
2.  **dev.kit is the Translator**: `dev.kit` translates complex repository logic into a standardized interface for both humans and AI.
3.  **Primary Skill**: Its core skill is to **Configure the Developer Environment** — orchestrating tools, environments, and AI assets into a single, high-fidelity engineering workflow.
4.  **The Result**: An **experienced dev flow without bullshit**.

## Overview

`dev.kit` acts as the orchestrator for your development environment. It translates local scripts, rules, and repository context into a unified engineering interface.

- **Smart Mapping**: Translates repo-scoped skills (`src/*`) and configurations into a stable CLI interface.
- **Orchestration**: Uses `environment.yaml` to orchestrate configurations across different hosts and environments.
- **AI-Enabled**: Provides high-fidelity prompts and MCP server fetching for deep AI integration.
- **Security First**: Built-in `doctor` command to ensure your engineering interface is safe and healthy.

## Operating Modes


### 1. Personal Helper Mode (`ai.enabled = false`)
**Use for local automation and shell consistency.**
- Core CLI commands (`config`, `doctor`, `task`, `prompt`).
- Local script mapping (`scripts/`, `lib/`).
- Scoped environment and context management.
- `dev.kit exec` generates and prints deterministic prompts for manual use in any tool.

### 2. AI-Powered Mode (`ai.enabled = true`)
**Use for deep automation and repository-aware agents.**
- Includes everything in Personal Helper mode.
- **Automated Execution**: Runs prompts directly through local AI CLIs (e.g., Codex).
- **Skill Mapping**: Maps local skills, rules, and agents to global AI providers.
- **MCP Integration**: Fetches MCP servers for deep tool access across repositories.
- **Context7 Knowledge**: Connects to the UDX `context7` ecosystem, making all UDX repositories effectively readable and known to AI agents.

## Install

Quick start:

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
source "$HOME/.udx/dev.kit/source/env.sh"
```

## Core Workflow

### 1. Doctor (Check & Advise)
Check your environment health and security status:
```bash
dev.kit doctor
```

### 2. Configure (Global & Repo)
Show or set configuration values:
```bash
dev.kit config show
dev.kit config set --key ai.enabled --value true
```

### 3. AI Mapping (Codex)
Map repo skills and rules to your global Codex agent:
```bash
dev.kit codex apply
```

### 4. Execute (Iterative Development)
Generate and run deterministic prompts:
```bash
dev.kit exec "Optimize dev.kit README"
```

### 5. Compliance Audit (Repo-as-a-Skill)
Ensure your repository is compliant with UDX engineering standards (TDD, 12-Factor, CaC, and Context Layer):
```bash
dev.kit audit
```

## Use Cases
... Applied fuzzy match at line 1-52.
- **Bootstrapping**: Standardize environment variables and tool paths across the team.
- **Skill Mapping**: Expose repository-specific capabilities (e.g., diagram generator) to your AI agent.
- **Iteration Loop**: Maintain session context and task history within the repo.

## Repo Map

- `bin/`: CLI entrypoints and installer.
- `lib/`: Runtime logic and command implementations.
- `src/ai/`: Source-of-truth for prompts, skills, and AI integration mapping.
- `tasks/`: Local storage for task prompts and feedback loops.

---
*UDX DevSecOps Team*
