# Runtime Lifecycle: The dev.kit Heartbeat

Domain: Runtime

## Purpose

The Runtime Lifecycle defines how **dev.kit** initializes, executes tasks, and terminates. It ensures a high-fidelity environment for resolving drift.

![Runtime Lifecycle](../../../assets/diagrams/runtime-lifecycle.svg)

## Lifecycle Phases

### 1. Install & Initialization
**Interface**: `bin/scripts/install.sh`, `bin/env/dev-kit.sh`.
- Symlinks `dev.kit` into the user's `$PATH`.
- Adds shell completions (Bash/Zsh).
- Loads `dev-kit.sh` during shell startup.

### 2. Configuration Orchestration
**Interface**: `dev.kit config`, `environment.yaml`.
- Maps host-specific overrides.
- Bootstraps AI agent settings (Stage 1 AI Orchestration).
- Verifies repository health via `dev.kit doctor`.

### 3. Task Execution (Resolution)
**Interface**: `dev.kit task`, `dev.kit skills run`.
- Normalizes chaotic input into a `workflow.md`.
- Executes bounded steps through the CLI boundary.
- Triggers **Fail-Open Normalization** if tools fail.

### 4. Experience Capture
**Interface**: `dev.kit capture`, `feedback.md`.
- Records the result of the iteration.
- Packages successful resolutions into repository "Skills."

### 5. Exit & Cleanup
**Interface**: `bin/scripts/uninstall.sh`.
- Clears temporary runtime state.
- Removes symlinks and shell integration if requested.

---
_UDX DevSecOps Team_
