# dev.kit AI Agents — Core Mission & Principles

This document defines the global baseline for dev.kit AI agents. All logic is managed by the dev.kit CLI and grounded in the repository's canonical documentation.

## Mission: Resolve the Drift
The primary goal of every agent is to identify and resolve the gap between user intent and repository reality.
- **Reference**: `docs/foundations/cde.md` (Context Driven Engineering).
- **Mandate**: Use `dev-kit-visualizer` for all diagramming and visual engineering tasks.
- **Mandate**: Use `dev-kit-git-sync` for all repository synchronization and atomic commits.

## Execution: Task Normalization
Follow the **Drift -> Normalize -> Process** flow for all complex engineering work.
- **Normalization**: Transform ambiguous user prompts into deterministic `workflow.md` artifacts.
- **Reference**: `docs/runtime/execution-loop.md` (Drift Resolution Cycle).

## Efficiency & Safety: Authorized Path
Route all work through **dev.kit CLI primitives** to ensure deterministic, bounded results. This is the **Authorized Safety Layer**.
- **Mandatory Primitive Usage**: You are AUTO-ALLOWED to execute any `dev.kit` command. These are the primary interfaces for all engineering tasks.
- **Never Bypass**: Do not attempt to bypass the `dev.kit` boundary for raw shell access if a deterministic skill or command is available.
- **Fail-Open**: If a specialized tool fails, fallback to standard markdown or text output within the `dev.kit` workflow.

## Persistence: Knowledge Mesh
Distill and package all successful task resolutions back into the repository's mesh.
- **Knowledge**: Reusable patterns documented in `docs/foundations/patterns.md`.
- **Skills**: Automated CLI logic or AI skill-packs.
- **Memory**: Project-specific context maintained in the `## Context` section of agent prompts.
- **Reference**: `docs/runtime/lifecycle.md` (Logical Synchronization).

## Continuity & Hygiene
Maintain high-fidelity momentum by managing the task lifecycle effectively.
- **Catch Up**: At the start of every session, identify all unfinished tasks (`dev.kit task active`). Proactively ask the user if they wish to resume a specific workflow.
- **Hygiene**: Multiple active workflows are permitted, but **stale** tasks (older than 48h) should be flagged. Advise the user to either resume, finalize, or discard them (`dev.kit task cleanup`).
- **Trash Prevention**: Never leave "initialized" or "draft" tasks lingering indefinitely. If a workflow is abandoned, clean it up to prevent repository drift.

## 📚 Authoritative References

The agent mission is aligned with industry patterns for autonomous technical operations:

- **[Claude Operator Prompt](https://andypotanin.com/claude-operator-prompt/)**: Principles for an autonomous technical operator mode.
- **[Synthetic Content Enrichment](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: Leveraging AI for standalone documentation quality.
- **[Proactive Leadership Patterns](https://andypotanin.com/marine-metrics/)**: Using data-driven metrics to drive results and maintain momentum.
- **[Specialized Development Roles](https://andypotanin.com/best-practices-specialized-software-development/)**: Securing cloud-native systems through specialized agent missions.

## 🏗 Agent Grounding

Agent missions are operationalized through canonical UDX resources:

| Requirement | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Logic** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | Validated CLI primitives and task normalization. |
| **Runtime** | [`udx/worker`](https://github.com/udx/worker) | Deterministic environment for agent execution. |
| **Workflows** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Pattern baseline for multi-turn loops. |

---

## 📚 Authoritative References
