# Abstract Layers

## Summary

These layers help categorize standards and decisions in dev.kit. They clarify whether a rule applies to build-time code, deployment-time behavior, or active context handling.

## Layer 1: Software Source Standards (Build)

Scope: how source code is structured, built, and validated.

Use when:
- defining build scripts
- adding linting and tests
- describing code ownership and module boundaries

Related docs:
- `docs/reference/yaml-standards.md`
- `docs/reference/principles.md`

## Layer 2: 12-Factor Standards (Deployment)

Scope: runtime behavior, configuration, environment parity, logging, and process model.

Notes:
- Treated as the deployment standard for repo-hosted services.

Use when:
- defining runtime layout and config strategy
- designing release pipelines
- setting operational expectations

Related docs:
- `docs/reference/12-factor.md`
- `docs/reference/lifecycle-cheatsheet.md`

## Layer 3: Context Driven Engineering (Active Context)

Scope: how context is captured, bounded, and used during iteration and automation.

Use when:
- designing prompts and workflows
- defining artifact and contract boundaries
- controlling AI execution behavior

Related docs:
- `docs/concepts/cde.md`
- `docs/concepts/cde.md`
- `docs/cli/execution/prompt-as-workflow.md`
