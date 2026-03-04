# dev.kit Documentation Index

Welcome to the **Smart Helper** documentation. This guide is structured to help you resolve the **Development Drift** from foundations to execution.

```mermaid
flowchart TD
    Foundations[1. Foundations] --> Setup[2. Setup & Runtime]
    Setup --> Flow[3. The Execution Flow]
    Flow --> AI[4. AI Orchestration]
    AI --> Ref[5. Engineering Reference Index]

    click Foundations "/docs/concepts/methodology.md"
    click Setup "/docs/cli/overview.md"
    click Flow "/docs/cli/execution/index.md"
    click AI "/docs/ai/README.md"
    click Ref "/docs/reference/udx-reference-index.md"
```

---

### 1. Foundations (Conceptual Model)
Understand the engineering vision behind **dev.kit**.
- **Methodology (CWA)**: `docs/concepts/methodology.md` - CLI-Wrapped Automation.
- **Context Driven Engineering (CDE)**: `docs/concepts/cde.md` - Resolving the Drift.
- **Context Adaptation**: `docs/concepts/adaptation.md` - Resilient Projections.
- **Core Principles**: `docs/reference/foundations/principles.md`.

### 2. Setup & Runtime (The Interface)
Configure your environment and understand the CLI surface.
- **Installation**: `README.md#install` - Quick start one-liner.
- **CLI Overview**: `docs/cli/overview.md` - Commands and wiring.
- **Configuration**: `docs/cli/config.md` - Using `environment.yaml`.
- **Runtime Lifecycle**: `docs/cli/runtime/lifecycle.md`.

### 3. The Execution Flow (Normalization)
Master the task normalization engine and deterministic workflows.
- **Execution Index**: `docs/cli/execution/index.md` - Flow entry point.
- **Task Normalization**: `docs/cli/execution/iteration-loop.md` - Drift to Resolution.
- **Workflow Schema (DOC-003)**: `docs/cli/execution/workflow-io-schema.md`.
- **Prompt-as-Workflow**: `docs/cli/execution/prompt-as-workflow.md`.

### 4. AI Orchestration (Agent Logic)
Leverage AI agents to automate the resolution of drift.
- **AI Integration**: `docs/ai/README.md` - Two-stage orchestration.
- **User Experience**: `docs/ai/experience.md` - High-fidelity prompting.
- **Skill Packs**: `src/ai/data/skill-packs/` - Repository-as-a-Skill.

### 5. Engineering Reference Index
A comprehensive map of all standards, compliance, and operational guidance.
- **Reference Index**: `docs/reference/udx-reference-index.md` - Start here for standards.
- **Standards & External Refs**: `docs/reference/standards/` - 12-Factor, Mermaid, YAML.
- **Compliance & Security**: `docs/reference/compliance/` - cATO, SLSA.
- **Operational Guidance**: `docs/reference/operations/` - Little's Law, SDLC Lifecycle.

---
_UDX DevSecOps Team_
