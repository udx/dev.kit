# dev.kit — Vision and Hierarchical Structure

This is the root document for dev.kit. It defines the non-negotiable
constraints and the hierarchy that all child documents must follow.

The purpose of this document is architectural control, not narrative.

---

## Entry Points

- Repo overview: `README.md`
- Docs navigation: `docs/README.md`
- Iteration loop: `docs/execution/iteration-loop.md`
- Subtask loop: `docs/execution/subtask-loop.md`
- CLI primitives: `docs/execution/cli-primitives.md`
- CLI structure: `docs/cli.md`
- Workflow IO schema (step state): `docs/execution/workflow-io-schema.md`
- Output contracts: `docs/cde/output-contracts.md`
- CDE contracts: `docs/cde/contracts.md`
- Prompt-as-workflow: `docs/execution/prompt-as-workflow.md`
- Prompts reference: `docs/prompts.md`
- Iteration skill contract: `src/ai/data/skills/iteration.json`
- Runtime boundary: `docs/runtime/index.md`
- Runtime layout: `docs/runtime/layout.md`

## Docs Map (Classic)

- CLI runtime: `docs/cli.md`, `docs/runtime/index.md`, `docs/runtime/layout.md`, `docs/execution/index.md`
- Configuration: `docs/config/index.md`
- Contracts and specs: `docs/cde/index.md`, `docs/specs.md`
- Mapping and adaptation: `docs/mapping/index.md`, `docs/adaptation.md`
- Prompts: `docs/prompts.md`
- Knowledgebase: `docs/knowledge.md`

## Core Engine Layout (Target)

- bin/
- lib/
- src/
- config/
- docs/
- src/ai/ (shared AI integration assets)
- src/ai/data/ (shared AI data)
- src/ai/integrations/ (integration-specific schemas/templates)
- src/prompts/ (prompt templates)
- src/mermaid/ (mermaid templates)
- src/docker/ (docker assets)
- src/ai/integrations/codex/schemas/ (Codex schema)
- src/ai/integrations/codex/templates/ (Codex render templates)
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

## 2. Core Principle: Context-Driven Engineering (CDE)

CDE is a universal repository discipline that makes systems:
- Understandable to humans
- Executable by programs
- Consumable by reasoning systems

Context is not documentation. Context is a constraint layer.
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

### 4.2 Repository
- Deterministic, structured, contractual.
- Consumed through defined interfaces, not raw inspection.

### 4.3 Context Artifacts
- Markdown, schemas, and manifests are the adaptation surface.
- Human-readable and machine-derivable.

### 4.4 CLI Runtime
- Primary execution interface.
- Enforces constraints and normalizes I/O.

### 4.5 Reasoning Systems
- Analyze, propose, explain.
- Do not execute or persist state.

---

## 5. System Layers

### 5.1 Software Design Constraints
- Components are decomposable.
- Each unit has clear inputs and deterministic outputs.

### 5.2 Repository as Contract (12-Factor++)
- Declares intent, rules, interfaces, and state.
- Assets are single-purpose and bounded.

### 5.3 CDE Artifacts
- Command schemas
- Input/output manifests
- Validation rules
- Context resolvers

### 5.4 CLI Runtime (dev.kit)
- Discovers repo-defined capabilities.
- Exposes stable, versioned commands.
- Executes workflows safely.
- Captures state and outputs.

---

## 6. Engineering Iteration Model

One iteration is a bounded pipeline:

input
→ analyze
→ configure
→ execute
→ post-validate
→ report
→ notify

Rules:
- Iterations are bounded and normalized.
- Output of iteration N becomes input to N+1.
- Pipelines must resolve to a single iteration boundary.

---

## 7. Domain Map (Child Documents)

1. Runtime
- CLI responsibilities and lifecycle
- Install/enable/uninstall
- Capability detection

2. Configuration
- Minimal defaults
- Opt-in integrations
- Reset and safety

3. Execution
- dev.kit exec as runtime wrapper
- Planning mechanisms are used for planning only
- Workflow boundaries
- Iteration loop and artifact cycle

4. CDE
- Artifact types and contracts
- Iteration as a contract surface

5. Context Adaptation
- Projections and filters
- Reasoning-system consumption contracts

6. Mapping
- Source → mapper → artifact
- Explicit sync and validation

---

## 7. Contract References

- Canonical intent sources are defined in the CDE contracts document.
- Stable interface scope is defined in the CDE contracts document.

## 8. Outcome

dev.kit enables:
- CDE-aligned repositories
- Standardized tooling interfaces
- Predictable iteration
- Safe reasoning-system usage

This is an engineering discipline, not an AI framework.
