---
name: dev-kit-compliance
description: MANDATORY skill for validating repository health against the 'Repo-as-a-Skill' standard. Audits for TDD maturity, 12-factor compliance, Config-as-Code (CaC), and active context layer readiness.
---

## Objective
Evaluate a repository's readiness for high-fidelity automation and AI interaction.

## CLI Usage Example
```bash
# Run a full compliance audit on the current repository
dev.kit audit

# Execute audit with detailed JSON output for reporting
dev.kit audit --json

# Run audit and fix common configuration isolation issues
dev.kit audit --fix
```

## Primary Skill: Repo-as-a-Skill Compliance Audit
The core capability of this skill is to evaluate a repository's readiness for high-fidelity automation and AI interaction. It ensures the repository is "compliant" with UDX engineering standards across four pillars:

### 1. TDD (Test Driven Development)
- Verify existence of a formal test suite (`tests/`, `test/`, `spec/`).
- Audit if testing is integrated into the iteration loop.
- **Goal**: Ensure every change is verifiable by humans, scripts, and LLMs.

### 2. 12-Factor Principles & CaC
- Audit for configuration isolation (e.g., gitignored `.env`).
- Verify the presence of an environment orchestrator (`environment.yaml`).
- Check for Infrastructure-as-Code and Configuration-as-Code maturity.
- **Goal**: Ensure the environment is portable, deterministic, and separate from the code.

### 3. Active Context Layer
- Audit for comprehensive internal documentation (`docs/`).
- Verify the existence of a task history (`tasks/`) for session continuity.
- Ensure the repository structure is self-describing for both humans and AI.
- **Goal**: Provide a high-fidelity context for the 'Smart Engineering Interface Translator'.

### 4. AI Mapping & Interface
- Verify the existence of a structured AI interface (`src/ai/`).
- Audit for MCP server definitions to empower AI agents with tool access.
- Ensure the repo correctly maps its internal capabilities to global AI skills.
- **Goal**: Transform the repository into a standalone, executable "Skill".

## Core Interface (CLI Primitive)
- `dev.kit audit`: Execute the compliance audit and receive actionable feedback.

## Compliance Feedback Loop
When `dev.kit audit` reports a warning or alert, the user should be advised to:
1.  **Resolve Isolation**: Move hardcoded configs to `environment.yaml` or `.env`.
2.  **Establish Context**: Create missing `docs/` or `tasks/`.
3.  **Define Skills**: Map internal logic into `src/ai/` as modular skills.
4.  **Implement Tests**: Bootstrap a test suite to close the validation loop.

## Result
A repository that is deterministic, portable, and natively understands how to interact with an experienced developer flow.

---
_UDX DevSecOps Team_
