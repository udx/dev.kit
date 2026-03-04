# The UDX Methodology: CLI-Wrapped Automation (CWA)

`dev.kit` uses **CLI-Wrapped Automation (CWA)** to normalize development processes.

## Core Concepts

1.  **Repo-as-a-Skill**: Every repository exposes its logic through standardized scripts and CLI commands.
2.  **Smart Helper**: `dev.kit` resolves **Drift** (intent divergence) by translating repository logic into a high-fidelity interface for humans and AI.

## The Principles

### 1. Task Normalization: Resolve the Drift
Chaotic intent is normalized into a deterministic `workflow.md`.
*   **Input Normalization**: Forced structure (`Scope`, `Inputs`, `Outputs`).
*   **State Normalization**: Tracked lifecycle (`planned -> in_progress -> done`).
*   **Bounded Execution**: Steps with strict limits; overflow triggers child workflows.

### 2. Resilient Waterfall (Fail-Open)
The development sequence remains unbroken through **Fail-Open Normalization**.
*   **Specialized Path**: Try the most high-fidelity tool first.
*   **Fallback Path**: Missing or failing tools trigger a fallback to **Standard Data** (raw text, logs).
*   **Continuity**: Outputs are always available to the next step, preventing environmental blocks.

### 3. Script-First & CLI-Wrapped
Logic is encapsulated in modular scripts (`scripts/`, `lib/`) and wrapped by the `dev.kit` CLI to ensure a consistent, deterministic environment.

### 4. AI-First Orchestration
`dev.kit` provides a stable interface for AI agents across two distinct stages:

*   **Stage 1: AI Integration & Environment Config**: Agents configure the environment with `dev.kit` and use its enforcement logic to maintain standards and rules.
*   **Stage 2: Agent Power via Task Normalization**: Agents leverage the `dev.kit` task normalization engine (Drift -> Normalize -> Iterate) to execute complex tasks reliably.

## The Execution Lifecycle

1.  **Plan**: Break intent into discrete CLI commands.
2.  **Normalize**: Standardize inputs, check environment health (`doctor`), and map context.
3.  **Process**: Execute logic and return a structured result.

## Why CWA?

*   **Portability**: Logic that works locally works everywhere.
*   **Maintainability**: UI (CLI) is decoupled from Logic (Scripts).
*   **Scalability**: Rapidly add and expose new "Skills."

_UDX DevSecOps Team_
