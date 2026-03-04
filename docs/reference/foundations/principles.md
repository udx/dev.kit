# Engineering Principles: Resolving the Drift

Domain: Reference

## Summary

These principles guide the design and execution of **dev.kit**. They provide the "why" behind every decision and help maintain a high-fidelity engineering interface for humans and AI agents.

## Core Principles

1.  **Resolve the Drift**: Every task is an attempt to close the gap between human intent and repository reality.
2.  **Deterministic Normalization**: Chaotic inputs must be transformed into bounded, repeatable workflows.
3.  **Resilient Waterfall (Fail-Open)**: Environment or tool failures should trigger standard data fallbacks, never blocking the execution sequence.
4.  **Repo-scoped Truth**: The repository is the absolute source of truth for all engineering skills, logic, and state.
5.  **Safe-by-Default CLI**: All execution happens through a validated CLI boundary with explicit confirmations and no hidden side effects.
6.  **Minimal Dependencies**: Prefer standard POSIX tools (Bash, Git) to ensure the highest portability across environments.
7.  **Ergonomic Artifacts**: Every output must be scannable by humans (Markdown) and consumable by machines (JSON/Prompts).

## Layering Model

- **Foundational Layer**: Core CLI wiring, shell integration, and repository-as-a-skill logic.
- **Orchestration Layer**: Environment configurations, agent bootstrapping, and rule enforcement.
- **Execution Layer**: Task normalization, bounded workflows, and resilient iteration loops.

## Decision Cues

- **If behavior is unpredictable**: Reduce implicit inputs and enforce a contract.
- **If a tool is missing**: Trigger the **Fail-Open Normalization** path.
- **If a task is complex**: Extract a child workflow via the **Extraction Gate**.
- **If intent is ambiguous**: Force a review step to re-identify the drift.

## Practical Checks

- Can this task be normalized into a `workflow.md`?
- Is the execution path resilient to a tool failure?
- Is the engineering experience captured as a reusable "Skill"?

---
_UDX DevSecOps Team_
