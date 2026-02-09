# Engineering Principles (dev.kit)

## Summary

These principles guide dev.kit design and documentation. They answer "why" behind decisions and help resolve ambiguous choices.

## Principles

- Deterministic outputs: same inputs produce the same results.
- Repo-scoped truth: local repo context is the primary source.
- Minimal dependencies: prefer bash and standard tools.
- Explicit boundaries: workflows are bounded and repeatable.
- Safe by default: avoid destructive actions without confirmation.
- Clear contracts: inputs, outputs, and schemas are explicit.
- Ergonomic logs: outputs are readable and actionable.

## Layering Model

- Build layer: software source standards and build-time rules.
- Deployment layer: runtime behavior and environment controls (12-factor).
- Active context layer: CDE guidance for prompts, artifacts, and workflows.

## Decision Cues

- If behavior varies, reduce implicit inputs.
- If docs are ambiguous, add a contract or example.
- If a tool is optional, make the fallback explicit.
- If a change is risky, add a confirmation gate.

## Practical Checks

- Can a user predict the output from the prompt and config?
- Are inputs and outputs documented in a single place?
- Is the smallest viable dependency set preserved?
