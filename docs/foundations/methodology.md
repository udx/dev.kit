# The UDX Methodology: CLI-Wrapped Automation (CWA)

**Domain:** Concepts / Operational Strategy  
**Status:** Canonical

## Summary

The **UDX Methodology** centers on **CLI-Wrapped Automation (CWA)**. This practice encapsulates all repository logic within a validated CLI boundary. By wrapping scripts and manifests in a standardized interface, we transform a static codebase into a high-fidelity "Skill" accessible to humans, CI/CD pipelines, and AI agents alike.

![Methodology Flow](../../assets/diagrams/methodology-flow.svg)

---

## Core Concepts

- **Repo-as-a-Skill**: Repository logic is not hidden in READMEs or tribal knowledge. It is exposed through standardized scripts and CLI commands. Engineering experience is captured as portable, executable automation.
- **The Smart Helper**: `dev.kit` acts as the orchestration layer that resolves **Drift** (intent divergence) by translating high-level goals into the specific repository-based skills required to achieve them.

---

## The Principles

### 1. Task Normalization: Resolving the Drift

Chaotic user intent is distilled into a deterministic `workflow.md`.

- **Structured Inputs**: Every task defines its `Scope`, `Inputs`, and `Expected Outputs`.
- **State Tracking**: The lifecycle is visible: `planned -> in_progress -> done`.
- **Bounded Execution**: Logic is executed in discrete steps. If a step exceeds its scope, it triggers a specialized sub-workflow rather than failing silently.

### 2. Resilient Waterfall (Fail-Open)

The engineering sequence must remain unbroken. We utilize **Fail-Open Normalization** to ensure continuity:

- **High-Fidelity Path**: Attempt execution using the most specialized tool/script first.
- **Fallback Path**: If specialized tools are missing or fail, the system falls back to **Standard Data** (raw logs, source code, or text-based reasoning).
- **Continuity**: The "Process" always yields an output, preventing environment blocks and allowing the next step to proceed with the best available data.

### 3. Script-First & CLI-Wrapped

Logic lives in modular, standalone scripts (`scripts/`, `lib/`). The `dev.kit` CLI provides the **Shell Wrapper** that ensures these scripts run in a consistent, environment-aware context (via `environment.yaml`).

### 4. Machine-Ready Orchestration

CWA provides a stable interface for AI agents across two stages:

- **Stage 1: Grounding**: Agents use `dev.kit` to audit the environment (`doctor`) and understand the "Rules of Engagement."
- **Stage 2: Execution**: Agents leverage the Task Normalization engine to execute complex, multi-step engineering loops with predictable results.

---

## The Execution Lifecycle: Plan → Normalize → Process

1.  **Plan**: Deconstruct the intent into discrete repository actions.
2.  **Normalize**: Validate the environment, map dependencies, and format the inputs into a `workflow.md`.
3.  **Process**: Execute the CLI commands and capture the result as a repository artifact.

---

## Why CWA?

- **Portability**: Logic that runs in the CLI works identically in Local Dev, CI/CD, and Production.
- **Decoupling**: The Interface (CLI) is separated from the Implementation (Scripts), allowing for seamless logic upgrades.
- **Zero Bloat**: Uses standard Markdown, YAML, and Shell. No proprietary "AI-only" formats required.

## 📚 Authoritative References

CWA is inspired by the transition toward decentralized and automated engineering flows:

- **[Embrace the Future: Decentralized DevOps](https://andypotanin.com/decentralized-devops-the-future-of-software-delivery/)**: The shift toward distributed service architectures.
- **[Automation-First Development](https://andypotanin.com/the-power-of-automation-how-it-has-transformed-the-software-development-process/)**: Breaking the struggle for efficiency through systematic automation.
- **[Digital Rails & Logistics](https://andypotanin.com/digital-rails-and-logistics/)**: Drawing parallels between software algorithms and automotive evolution.
- **[AOCA: The Automation Baseline](https://udx.io/cloud-automation-book/automation-best-practices)**: Establishing standardized CLI wrappers for reduced variance.

---
_UDX DevSecOps Team_

