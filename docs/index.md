# dev.kit — Vision and Hierarchical Structure

This is the root document for dev.kit. It defines the hierarchy
and the guardrails that child documents should follow.

The purpose of this document is architectural control, not narrative.

---

## Entry Points

- Repo overview: `README.md`
- Docs navigation: `docs/README.md`
- CLI overview: `docs/cli/overview.md`
- AI integration: `docs/ai/README.md`
- Concepts: `docs/concepts/index.md`
- References: `docs/reference/udx-reference-index.md`
- Iteration skill contract: `src/ai/data/skills/dev-kit-iteration.json`

## Docs Map (Classic)

- CLI and execution: `docs/cli/overview.md`, `docs/cli/execution/index.md`
- AI integration: `docs/ai/README.md`
- Concepts and specs: `docs/concepts/index.md`, `docs/concepts/specs.md`
- References: `docs/reference/udx-reference-index.md`
- Knowledgebase: `docs/reference/knowledge.md`

## Core Engine Layout (Target)

- bin/
- lib/
- src/
- config/
- docs/
- src/ai/ (shared AI integration assets)
- src/ai/data/ (shared AI data)
- src/ai/integrations/ (integration-specific schemas/templates)
- src/ai/data/prompts.json (prompt templates)
- src/mermaid/ (mermaid templates)
- src/docker/ (docker assets)
- scripts/
- tasks/ (optional)
- schemas/ (optional)
- assets/
- extensions/

## Install & Shell Init

Install with:
`curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash`

Then source the shell init (if the installer didn’t prompt to update your profile):
`source "$HOME/.udx/dev.kit/source/env.sh"`

## 1. Why dev.kit Exists

Modern engineering systems fail to leverage automation and AI because
interfaces and constraints are missing, not because capability is missing.

### 1.1 Tooling Entropy
- Tool selection is ad hoc.
- Invocation patterns are inconsistent.
- Best practices exist but are not executable.

### 1.2 Unbounded Reasoning
- Reasoning systems operate without hard contracts.
- Output drifts and becomes unsafe.
- Intent, proposal, and execution are not separated.

### 1.3 Scale Mismatch
- Reasoning works best on small units of work.
- Engineering is large, iterative, and stateful.
- Decomposition is informal and inconsistent.

### 1.4 Missing Iteration Semantics
- There is no shared iteration boundary.
- Outputs are not normalized or chained.
- Automation becomes opaque and unsafe.

---

## 2. Working Principle: Context-Driven Engineering (CDE)

CDE is a working model that helps make systems:
- Understandable to humans
- Executable by programs
- Consumable by reasoning systems

Context is more than documentation. It is a constraint layer.
There is no separate AI layer.

---

## 3. Architectural Dependency Chain (Mandatory)

Software Design
→ Repository Contract
→ CDE Artifacts
→ CLI Runtime

Reasoning systems consume the system through these layers.

---

## 4. Responsibility Boundaries

### 4.1 Source Code
- Written for compilers and interpreters.
- Readable for humans and tools, not for reasoning systems.

### 4.2 Documentation
- Canonical intent and stable interface declarations.
- Human-readable first, then machine-normalized.

### 4.3 Artifacts
- Machine-readable representations of intent.
- Prompt artifacts, schemas, and manifests.

### 4.4 CLI Runtime
- Execution boundary and validation gate.
- Enforces determinism and safety.
