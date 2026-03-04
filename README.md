<img src="assets/logo.svg" alt="dev.kit logo" width="200">

# dev.kit — Resolve the Development Drift

**Experienced engineering flow with no-bullshit results.**

`dev.kit` resolves the **Drift** (intent divergence) by **Normalizing** it into a deterministic path and **Iterating** to the result.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
source "$HOME/.udx/dev.kit/source/env.sh"
```

## The "Big 4" Core Commands

Simplified primitives allow you to focus on the intent, not the CLI syntax.

- **`dev.kit <intent>`**: Implicitly executes AI-powered requests.
- **`dev.kit ai`**: Unified AI management (Sync, Skills, Status).
- **`dev.kit task`**: Engineering lifecycle (Start, Log, Reset).
- **`dev.kit config`**: Environment settings and orchestrator.
- **`dev.kit status`**: (Default) Engineering brief and system diagnostic.

## The Engineering Loop: Feature Flow

```bash
# 1. One-shot Intent (Implicit execution)
dev.kit "Implement user auth"

# 2. Start a context-tracked task
dev.kit task start "Refactor sync script"

# 3. Synchronize AI state
dev.kit ai sync

# 4. Inspect session history
dev.kit task log
```

## 🧠 Core Philosophy

### 1. Interactive Normalization (STOP & ASK)
Agents operate with a **Normalization Gate**. If an intent is ambiguous, the agent will **STOP and ASK** for clarification rather than guessing.

### 2. Repository-as-a-Skill
Every repository is a standalone **Skill**. `dev.kit` maps internal logic into a unified interface for humans and AI agents.

## Documentation

- **Scenarios & Workflows**: `docs/scenarios/README.md`
- **CLI Overview**: `docs/cli/overview.md`
- **AI Integration**: `docs/ai/README.md`

_UDX DevSecOps Team_
