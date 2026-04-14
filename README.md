# dev.kit

<https://udx.dev/kit>

**A foundation for context-driven development.**

`dev.kit` builds structured context from environment, repository, and accumulated experience — so development is grounded in what actually exists, not assumptions.

It resolves a repository into a working system — tracing dependencies and linking manifests to the tools they actually drive.

AI Agents can operate without knowledge drift or guesswork — developers orchestrate and validate.

---

## How it works

`dev.kit` builds context in layers:

- **Environment** → what actually works  
- **Repo** → how the system is structured  
- **Experience** → signals from real usage  

This produces a resolved view of the system that can be used directly or by automation.

Each layer reduces guesswork.

---

## Quick start

```bash
dev.kit
dev.kit repo
dev.kit agent
```

---

## Commands

### `dev.kit` — environment

Validates your environment and records what’s available.

Everything downstream relies only on tools that actually work.

```bash
dev.kit
dev.kit --json
```

---

### `dev.kit repo` — repo

Builds a resolved view of your repository.

On an **existing repo**:

- reads docs, workflows, Dockerfiles, and manifests  
- incorporates issues and PRs (if available)  
- identifies gaps against 12-factor principles  

On a **new repo**:

- scaffolds missing structure  
- creates `.gitignore`, `AGENTS.md`, and workflow stubs  

```bash
cd my-repo
dev.kit repo
```

---

### `dev.kit agent` — agent

Executes tasks using the resolved context.

- reads repo context  
- updates `AGENTS.md`  
- works against real constraints, not prompts  

```bash
dev.kit agent
```

Works with any agent that can read files.

---

## Without agents

Use `dev.kit` directly to:

- validate your environment  
- understand repositories  
- identify structural gaps  
- scaffold and standardize projects  

Context is the core output. Agents consume it.

---

## Why

**Context over prompts**  
Prompts provide intent. Context prevents drift.

**Resolved systems**  
Dependencies and tools are explicit and connected.

**Incremental**  
Each step adds value on its own.

**Agent-compatible**  
Plain files and structured output — no lock-in.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
```

---

## Docs

- [Overview](docs/overview.md)
- [Commands](docs/commands.md)
- [Workflow Model](docs/workflow.md)
- [Architecture](docs/architecture.md)
- [Detection Facets](docs/detection-facets.md)
